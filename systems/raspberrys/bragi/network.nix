{
  config,
  sensitive,
  ...
}: {
  # TODO: can this live in rift?
  networking = {
    useNetworkd = true;
    firewall = {
      enable = true;
      allowedTCPPorts = with sensitive.network.port.tcp.bragi; [
        nginx
        nginxSSL
        samba
        ftp.main
      ];
      allowedTCPPortRanges = with sensitive.network.port.tcp.bragi; [
        {
          from = ftp.passive.min;
          to = ftp.passive.max;
        }
      ];
      allowedUDPPorts = [sensitive.network.port.udp.alesia.wireguard];
    };
    interfaces = {
      end0 = {
        useDHCP = true;
        ipv4.addresses = [
          {
            address = sensitive.network.ip.bragi.lab;
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
        PrivateKeyFile = config.sops.secrets.wg-bragi-private-key.path;
        RouteTable = "main"; # To automatically create routes for everything in AllowedIPs,
        FirewallMark = sensitive.network.wireguard.firewallMark;
      };
      wireguardPeers = [
        {
          PublicKey = sensitive.keys.wireguard.alesia.pub;
          PresharedKeyFile = config.sops.secrets."wg-bragi-psk".path;
          AllowedIPs = [
            "${sensitive.network.ip.alesia.viae}/24"
            "${sensitive.network.ip.alesia.hodos}/24"
          ];
          Endpoint = "${sensitive.network.ip.alesia.public}:${toString sensitive.network.port.udp.alesia.wireguard}";
          # NOTE: PersistentKeepalive needed to keep the channel between alesia and bragi alive.
          # Otherwise if a connection was not already in place (initiated by bragi) alesia would not
          # know where to route the requests from other peers to bragi
          PersistentKeepalive = 25;
        }
      ];
    };

    networks = {
      "10-end0" = {
        matchConfig.Name = "end0";
        networkConfig.DHCP = "yes";
        address = [
          "${sensitive.network.ip.bragi.lab}/24"
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
          "${sensitive.network.ip.bragi.viae}/32"
          "${sensitive.network.ip.bragi.hodos}/32"
        ];
      };
    };
  };
}
