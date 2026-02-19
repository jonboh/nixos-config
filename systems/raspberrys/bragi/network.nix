{sensitive, ...}: {
  networking = {
    firewall = {
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
}
