{
  config,
  sensitive,
  ...
}: {
  networking = {
    hostName = "thule";
    useNetworkd = true;
    firewall = {
      enable = true;
    };
    interfaces.end0.useDHCP = true;
    timeServers = [(sensitive.network.ntp-server "lab")];
    nameservers = [(sensitive.network.dns-server "lab")];
  };
  systemd.network = {
    enable = true;
    wait-online.enable = false;

    networks = {
      "10-end0" = {
        matchConfig.Name = "end0";
        networkConfig.DHCP = "yes";
      };
    };
  };
}
