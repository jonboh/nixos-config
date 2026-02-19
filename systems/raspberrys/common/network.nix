{
  config,
  lib,
  ...
}: {
  options.jonboh.configure.rpiEthernet.enable = lib.mkEnableOption "Enable or disable the network configuration for end0";

  config = lib.mkIf config.jonboh.configure.rpiEthernet.enable {
    networking = {
      useNetworkd = true;
      usePredictableInterfaceNames = true;
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
  };
}
