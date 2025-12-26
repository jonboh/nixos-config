{
  lib,
  sensitive,
  config,
  ...
}: {
  options = {
    configure.ntpd-rs.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Configure ntpd-rs";
    };
  };
  config.services.ntpd-rs = lib.mkIf config.configure.ntpd-rs.enable {
    enable = true;
    settings = {
      source = [
        {
          address = sensitive.network.ntp-server "lab";
          mode = "server";
        }
      ];
      observability.ansi-colors = false;
      synchronization = {
        minimum-agreeing-sources = 1;
        single-step-panic-threshold = 1000;
        startup-step-panic-threshold = {
          forward = "inf";
          backward = 86400;
        };
      };
    };
    useNetworkingTimeServers = false;
  };
  config.systemd.services.ntpd-rs.serviceConfig = lib.mkDefault {
    Restart = "on-failure";
    RestartSec = "5min";
  };
}
