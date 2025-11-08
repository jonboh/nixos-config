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
    };
  };
}
