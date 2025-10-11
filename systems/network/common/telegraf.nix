{
  self,
  pkgs,
  config,
  lib,
  modulesPath,
  ...
}: {
  services.telegraf = {
    enable = true;
    environmentFiles = ["/run/secrets_derived/influxdb.env"];
    extraConfig = {
      inputs = {
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
}
