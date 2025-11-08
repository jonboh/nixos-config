{pkgs, ...}: {
  services.telegraf = {
    enable = true;
    environmentFiles = ["/run/secrets_derived/influxdb.env"];
    extraConfig = {
      agent = {
        interval = "10s";
        collection_jitter = "5s";
        flush_interval = "60s";
        flush_jitter = "30s";
      };
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
