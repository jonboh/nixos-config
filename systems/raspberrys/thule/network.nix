{
  networking = {
    hostName = "thule";
    useNetworkd = true;
    interfaces.end0.useDHCP = true;
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
