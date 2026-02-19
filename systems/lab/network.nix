{sensitive, ...}: {
  networking = {
    useNetworkd = true;
    hostName = "lab";
    firewall = {
      allowedTCPPorts = with sensitive.network.port.tcp.bragi; [samba];
      allowedUDPPorts = with sensitive.network.port.udp; [alesia.wireguard lab.ntp];
    };
  };

  systemd.network = {
    enable = true;
    wait-online.enable = false;

    networks = {
      "enp10s0" = {
        matchConfig.Name = "enp10s0";
        networkConfig.DHCP = "yes";
        address = [
          "${sensitive.network.ip.lab.lab}/24"
        ];
      };
    };
  };
}
