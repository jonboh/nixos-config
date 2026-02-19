{sensitive, ...}: {
  networking = {
    hostName = "workstation";
    wireless.enable = false;
    networkmanager = {
      enable = true;
      unmanaged = [
        "eno1"
        "wg0"
      ];
    };
    # Steamlink
    firewall.allowedTCPPorts = sensitive.network.port.tcp.workstation.list.steamlink;
    firewall.allowedUDPPorts =
      [
        sensitive.network.port.udp.alesia.wireguard
      ]
      ++ sensitive.network.port.udp.ros-comms;
  };

  jonboh.configure.ntpd-rs.enable = true;
  networking.useNetworkd = true;

  systemd.network = {
    enable = true;
    wait-online.enable = true;

    networks = {
      "10-eno1" = {
        matchConfig.Name = "eno1";
        networkConfig.DHCP = "yes";
      };
    };
  };
}
