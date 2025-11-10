{
  self,
  config,
  pkgs,
  lib,
  ...
}: {
  options = {
    configure.hardware-metrics = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable hardware metrics collection";
      };
      thermal_zone0-temperature = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable Raspberry Pi temperature metrics";
        };
      };
      temperature = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enables telegraf temp input";
        };
      };
    };
  };

  config = {
    services.telegraf = lib.mkIf config.configure.hardware-metrics.enable {
      enable = true;
      environmentFiles = ["/run/secrets_derived/influxdb.env"];
      extraConfig = {
        inputs =
          {
            internal = {};
            mem = {};
            cpu = {
              totalcpu = true;
            };
            disk = {
              ignore_fs = ["tmpfs" "devtmpfs"];
            };
            diskio = {};
            swap = {};
            system = {};
          }
          // lib.optionalAttrs config.configure.hardware-metrics.temperature.enable {
            temp = {}; # TODO: add a name_override to match against existing cpu_temp
          }
          // lib.optionalAttrs config.configure.hardware-metrics.thermal_zone0-temperature.enable {
            exec = [
              {
                name_override = "cpu_temp";
                commands = [
                  (pkgs.writeScript "read-temp" ''
                    #!/bin/sh
                    ${pkgs.coreutils}/bin/cat /sys/class/thermal/thermal_zone0/temp | ${pkgs.gawk}/bin/awk '{print $1/1000}'
                  '')
                ];
                data_format = "value";
                data_type = "float";
              }
            ];
          };

        outputs = {
          file = {
            files = ["/tmp/influx_metrics.out"];
            rotation_max_size = "1MB";
            rotation_max_archives = 10;
          };
          influxdb_v2 = {
            urls = ["https://influx.jonboh.dev"];
            token = "$INFLUXDB_TOKEN";
            organization = "jonboh";
            bucket = "sensors";
          };
        };
      };
    };

    systemd.services.telegraf = lib.mkIf config.configure.hardware-metrics.enable {
      after = ["derived-secrets.service"];
      wants = ["derived-secrets.service"];
      serviceConfig = {
        # Keep retrying if failed to start
        StartLimitBurst = 10000;
        Restart = lib.mkForce "always";
        RestartSec = "5s";
      };
    };

    systemd.services.derived-secrets = lib.mkIf config.configure.hardware-metrics.enable {
      description = "Create a dotenv file for Telegraf to consume";
      wantedBy = ["multi-user.target" "telegraf.service"];
      path = [pkgs.coreutils];
      script = ''
        set -e
        token=$(cat ${config.sops.secrets.influxdb-token.path})
        mkdir -p /run/secrets_derived/
        echo "INFLUXDB_TOKEN=$token" > /run/secrets_derived/influxdb.env
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };
    sops.secrets.influxdb-token = lib.mkIf config.configure.hardware-metrics.enable {
      format = "binary";
      sopsFile = self.inputs.nixos-config-sensitive + /secrets/influxdb-token;
      restartUnits = ["derived-secrets.service" "telegraf.service"];
    };
  };
}
