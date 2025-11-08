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
    };
  };
}
