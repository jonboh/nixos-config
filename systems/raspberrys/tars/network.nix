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
      };
    };
  };
}
