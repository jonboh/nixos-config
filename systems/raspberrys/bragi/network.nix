{sensitive, ...}: {
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
      };
    };
  };
}
