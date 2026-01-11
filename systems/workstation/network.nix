{
  config,
  sensitive,
  ...
}: {
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
    nameservers = [(sensitive.network.dns-server "lab")];
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
        address = [
          "${sensitive.network.ip.workstation.lab}/24"
        ];
        routes = [
          {
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
