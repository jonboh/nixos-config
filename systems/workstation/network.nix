{
  config,
  sensitive,
  ...
}: {
  networking = {
    hostName = "workstation";
    wireless.enable = false;
    networkmanager = {
      enable = true;
      unmanaged = [
        "eno1"
        "wg0"
      ];
    };
    nameservers = [(sensitive.network.dns-server "lab")];
    # Steamlink
    firewall.allowedTCPPorts = sensitive.network.port.tcp.workstation.list.steamlink;
    firewall.allowedUDPPorts = [sensitive.network.port.udp.alesia.wireguard] ++ sensitive.network.port.udp.workstation.list.steamlink;
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
    wait-online.enable = true;

    netdevs."50-wg0" = {
      netdevConfig = {
        Kind = "wireguard";
        Name = "wg0";
      };

      wireguardConfig = {
        ListenPort = sensitive.network.port.udp.alesia.wireguard;
        PrivateKeyFile = config.sops.secrets.wg-workstation-private-key.path;
        RouteTable = "main"; # To automatically create routes for everything in AllowedIPs
        FirewallMark = 42;
      };
      wireguardPeers = [
        {
          PublicKey = sensitive.keys.wireguard.alesia.pub;
          PresharedKeyFile = config.sops.secrets."wg-workstation-psk".path;
          AllowedIPs = [
            "${sensitive.network.ip.alesia.viae}/24"
          ];
          Endpoint = "${sensitive.network.ip.alesia.public}:${toString sensitive.network.port.udp.alesia.wireguard}";
        }
      ];
    };

    networks = {
      "10-eno1" = {
        matchConfig.Name = "eno1";
        networkConfig.DHCP = "yes";
        address = [
          "${sensitive.network.ip.workstation.lab}/24"
        ];
        routes = [
          {
            Gateway = sensitive.network.ip.charon.lab;
          }
          {
            Destination = sensitive.network.vlan-range "rift";
            Gateway = sensitive.network.ip.charon.lab;
          }
          {
            Destination = sensitive.network.vlan-range "warp";
            Gateway = sensitive.network.ip.charon.lab;
          }
        ];
      };
      "50-wg0" = {
        matchConfig.Name = "wg0";
        address = [
          "${sensitive.network.ip.workstation.viae}/32"
        ];
      };
    };
  };
}
