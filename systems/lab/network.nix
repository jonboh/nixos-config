{
  pkgs,
  config,
  sensitive,
  ...
}: {
  networking = {
    hostName = "lab";
    networkmanager.enable = false;
    wireless.enable = false;
    nameservers = [(sensitive.network.dns-server "lab")];
    # Steamlink
    firewall.allowedUDPPorts = [sensitive.network.port.udp.alesia.wireguard];
  };
  services.ntpd-rs = {
    enable = true;
    settings = {
      source = [
        {
          address = sensitive.network.ntp-server "lab";
          mode = "server";
        }
      ];
      synchronization = {
        minimum-agreeing-sources = 1;
        single-step-panic-threshold = 1000;
        startup-step-panic-threshold = {
          forward = "inf";
          backward = 86400;
        };
      };
    };
    useNetworkingTimeServers = false;
  };
  networking.useNetworkd = true;

  systemd.network = {
    enable = true;
    wait-online.enable = false;

    netdevs."50-wg0" = {
      netdevConfig = {
        Kind = "wireguard";
        Name = "wg0";
      };

      wireguardConfig = {
        ListenPort = sensitive.network.port.udp.alesia.wireguard;
        PrivateKeyFile = config.sops.secrets.wg-lab-private-key.path;
        RouteTable = "main"; # To automatically create routes for everything in AllowedIPs,
        FirewallMark = sensitive.network.wireguard.firewallMark;
      };
      wireguardPeers = [
        {
          PublicKey = sensitive.keys.wireguard.alesia.pub;
          PresharedKeyFile = config.sops.secrets."wg-lab-psk".path;
          AllowedIPs = [
            "${sensitive.network.ip.alesia.viae}/24"
            "${sensitive.network.ip.alesia.hodos}/24"
          ];
          Endpoint = "${sensitive.network.ip.alesia.public}:${toString sensitive.network.port.udp.alesia.wireguard}";
          # NOTE: PersistentKeepalive needed to keep the channel between alesia and lab alive.
          # Otherwise if a connection was not already in place (initiated by lab) alesia would not
          # know where to route the requests from other peers to lab
          PersistentKeepalive = 25;
        }
      ];
    };

    networks = {
      "enp10s0" = {
        matchConfig.Name = "enp10s0";
        networkConfig.DHCP = "yes";
        address = [
          "${sensitive.network.ip.lab.lab}/24"
        ];
        routes = [
          {
            Gateway = sensitive.network.ip.charon.lab;
          }
        ];
      };
      "50-wg0" = {
        matchConfig.Name = "wg0";

        address = [
          "${sensitive.network.ip.lab.viae}/32"
          "${sensitive.network.ip.lab.hodos}/32"
        ];
      };
    };
  };

  environment.systemPackages = [pkgs.wireguard-tools];
}
