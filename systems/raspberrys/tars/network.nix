{
  config,
  sensitive,
  ...
}: {
  networking = {
    useNetworkd = true;
    firewall = {
      enable = true;
      allowedTCPPorts = with sensitive.network.port.tcp.tars; [
        nginx
        nginxSSL
        samba
        mqtt
      ];
      allowedUDPPorts = [sensitive.network.port.udp.alesia.wireguard];
    };
    interfaces = {
      end0 = {
        useDHCP = true;
        ipv4.addresses = [
          {
            address = sensitive.network.ip.tars.lab;
            prefixLength = 24;
          }
        ];
      };
    };
    timeServers = [(sensitive.network.ntp-server "lab")];
    nameservers = [(sensitive.network.dns-server "lab")];
  };
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
        PrivateKeyFile = config.sops.secrets.wg-tars-private-key.path;
        RouteTable = "main"; # To automatically create routes for everything in AllowedIPs
        FirewallMark = sensitive.network.wireguard.firewallMark;
      };
      wireguardPeers = [
        {
          PublicKey = sensitive.keys.wireguard.alesia.pub;
          PresharedKeyFile = config.sops.secrets."wg-tars-psk".path;
          AllowedIPs = [
            "${sensitive.network.ip.alesia.viae}/24"
          ];
          Endpoint = "${sensitive.network.ip.alesia.public}:${toString sensitive.network.port.udp.alesia.wireguard}";
          # NOTE: PersistentKeepalive needed to keep the channel between alesia and tars alive.
          # Otherwise if a connection was not already in place (initiated by tars) alesia would not
          # know where to route the requests from other peers to tars
          PersistentKeepalive = 25;
        }
      ];
    };

    networks = {
      "10-end0" = {
        matchConfig.Name = "end0";
        networkConfig.DHCP = "yes";
        address = [
          "${sensitive.network.ip.tars.lab}/24"
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
          "${sensitive.network.ip.tars.viae}/32"
        ];
      };
    };
  };
}
