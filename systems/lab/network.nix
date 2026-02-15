{sensitive, ...}: {
  networking = {
    hostName = "lab";
    networkmanager.enable = false;
    wireless.enable = false;
    firewall = {
      allowedTCPPorts = with sensitive.network.port.tcp.bragi; [
        samba
      ];
      allowedUDPPorts = [sensitive.network.port.udp.alesia.wireguard sensitive.network.port.udp.lab.ntp];
    };
  };
  networking.useNetworkd = true;

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
