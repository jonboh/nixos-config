{
  lib,
  sensitive,
  config,
  ...
}: {
  options = {
    jonboh.configure.ntpd-rs.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Configure ntpd-rs";
    };
    jonboh.configure.ntpd-rs.source = lib.mkOption {
      type = lib.types.enum ["local" "internet"];
      default = "local";
      description = "Source for ntpd-rs, either local or internet.";
    };
  };
  config.services.ntpd-rs = lib.mkIf config.jonboh.configure.ntpd-rs.enable {
    enable = true;
    settings = {
      source =
        if config.jonboh.configure.ntpd-rs.source == "local"
        then [
          {
            address = sensitive.network.ntp-server "lab";
            mode = "server";
          }
        ]
        else [
          {
            address = "pool.ntp.org";
            mode = "pool";
          }
          {
            address = "0.nixos.pool.ntp.org";
            mode = "pool";
          }
          {
            address = "1.nixos.pool.ntp.org";
            mode = "pool";
          }
          {
            address = "2.nixos.pool.ntp.org";
            mode = "pool";
          }
          {
            address = "3.nixos.pool.ntp.org";
            mode = "pool";
          }
          {
            address = "ntpd-rs.pool.ntp.org";
            mode = "pool";
          }

          # source: https://wiki.bandaancha.st/Lista_de_servidores_NTP_stratum_1_en_Espa%C3%B1a
          {
            address = "130.206.3.166";
            mode = "server";
          }
          {
            address = "130.206.0.1";
            mode = "server";
          }
          {
            address = "150.214.94.5";
            mode = "server";
          }
          {
            address = "150.214.94.10";
            mode = "server";
          }
          {
            address = "193.147.107.33";
            mode = "server";
          }
          {
            address = "185.179.104.7";
            mode = "server";
          }
          {
            address = "185.179.104.12";
            mode = "server";
          }
          {
            address = "150.214.5.121";
            mode = "server";
          }
          {
            address = "158.227.98.15";
            mode = "server";
          }
        ];
      synchronization = {
        minimum-agreeing-sources =
          if config.jonboh.configure.ntpd-rs.source == "local"
          then 1
          else 5;
        single-step-panic-threshold = 1000;
        startup-step-panic-threshold = {
          forward = "inf";
          backward = 86400;
        };
      };

      observability.ansi-colors = false;
    };
    useNetworkingTimeServers = false;
  };
  config.systemd.services.ntpd-rs.serviceConfig = lib.mkDefault {
    Restart = "on-failure";
    RestartSec = "5min";
  };
}
