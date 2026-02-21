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
    firewall.allowedUDPPorts =
      [
        sensitive.network.port.udp.alesia.wireguard
      ]
      ++ sensitive.network.port.udp.ros-comms;
  };

  jonboh.configure.ntpd-rs.enable = true;

  systemd.network = {
    enable = true;
    wait-online.enable = true;

    networks = {
      "10-eno1" = {
        matchConfig.Name = "eno1";
        networkConfig.DHCP = "yes";
        routes = [
          {
            Destination = sensitive.network.vlan-range "lab";
            Gateway = sensitive.network.ip.charon.lab;
          }
          {
            Destination = sensitive.network.vlan-range "charon";
            Gateway = sensitive.network.ip.charon.lab;
          }
          {
            Destination = sensitive.network.vlan-range "rift";
            Gateway = sensitive.network.ip.charon.lab;
          }
          {
            Destination = sensitive.network.vlan-range "warp";
            Gateway = sensitive.network.ip.charon.lab;
          }
        ];
      };
    };
  };
}
