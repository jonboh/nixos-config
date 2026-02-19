{sensitive, ...}: {
  networking = {
    firewall = {
      allowedTCPPorts = with sensitive.network.port.tcp.tars; [
        nginx
        nginxSSL
        samba
        mqtt
      ];
      allowedUDPPorts = [sensitive.network.port.udp.alesia.wireguard];
    };
  };
}
