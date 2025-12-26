{
  pkgs,
  config,
  sensitive,
  ...
}: {
  networking = {
    hostName = "lab";
    networkmanager.enable = false;
    wireless.enable = false;
    nameservers = [(sensitive.network.dns-server "lab")];
    firewall.allowedUDPPorts = [sensitive.network.port.udp.alesia.wireguard];
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
        routes = [
          {
            Gateway = sensitive.network.ip.charon.lab;
          }
        ];
      };
    };
  };
}
