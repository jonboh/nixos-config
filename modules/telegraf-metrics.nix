# Telegraf Metrics Collection Module
#
# This module provides comprehensive metrics collection via Telegraf, including:
# - Hardware metrics (CPU, memory, disk, temperature) 
# - Process metrics (per-process resource usage)
# - Separate InfluxDB buckets for hardware and process metrics
#
# Usage Examples:
#   # Enable hardware metrics only
#   jonboh.configure.telegraf-metrics = {
#     enable = true;
#     hardware-metrics.enable = true;
#   };
#
#   # Enable both hardware and process metrics
#   jonboh.configure.telegraf-metrics = {
#     enable = true;
#     hardware-metrics = {
#       enable = true;
#       temperature.enable = true;      # Enable temperature sensors
#     };
#     process-metrics.enable = true;    # Enable per-process monitoring
#   };
#
#   # Raspberry Pi with thermal monitoring
#   jonboh.configure.telegraf-metrics = {
#     enable = true;
#     hardware-metrics.thermal_zone0-temperature.enable = true;
#   };
#
# InfluxDB Buckets:
# - Hardware metrics → "hardware" bucket
# - Process metrics → "processes" bucket
#
# Historical process resource usage can be queried in Grafana for analysis.
#
{
  self,
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.jonboh.configure.telegraf-metrics;
  
  # Helper function to determine if Telegraf should be enabled
  telegrafEnabled = cfg.enable && (cfg.hardware-metrics.enable || cfg.process-metrics.enable);
  
  # Base Telegraf agent configuration
  baseAgentConfig = {
    interval = cfg.collection_interval;
    round_interval = true;
    metric_batch_size = 1000;
    metric_buffer_limit = 10000;
    collection_jitter = "3s";
    flush_interval = "60s";
    flush_jitter = "5s";
    debug = false;
    skip_processors_after_aggregators = false;
  };
  
  # Hardware metrics inputs
  hardwareInputs = lib.optionalAttrs cfg.hardware-metrics.enable (
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
    // lib.optionalAttrs cfg.hardware-metrics.temperature.enable {
      temp = {}; # TODO: add a name_override to match against existing cpu_temp
    }
    // lib.optionalAttrs cfg.hardware-metrics.thermal_zone0-temperature.enable {
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
    }
  );
  
  # Process metrics inputs
  processInputs = lib.optionalAttrs cfg.process-metrics.enable {
    procstat = 
      (lib.optionals cfg.process-metrics.monitor_all_processes [
        {
          pattern = ".*";
          pid_finder = "pgrep";
          
          # Use modern tag_with syntax instead of deprecated *_tag options
          tag_with = ["pid" "cmdline" "user"];
        }
      ]) ++ 
      # Add specific process monitoring if patterns are specified
      (map (pattern: {
        pattern = pattern;
        pid_finder = "pgrep";
        
        # Use modern tag_with syntax
        tag_with = ["pid" "cmdline" "user"];
      }) cfg.process-metrics.specific_processes);
  };

in {
  options = {
    jonboh.configure.telegraf-metrics = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Telegraf metrics collection";
      };
      
      collection_interval = lib.mkOption {
        type = lib.types.str;
        default = "30s";
        description = "Base collection interval for all metrics";
      };
      
      hardware-metrics = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable hardware metrics collection (CPU, memory, disk, etc.)";
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
            description = "Enable generic temperature sensor inputs";
          };
        };
      };
      
      process-metrics = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable process metrics collection via procstat";
        };
        
        monitor_all_processes = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Monitor all running processes";
        };
        
        specific_processes = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "List of specific process patterns to monitor (regex patterns)";
          example = ["nginx" "postgres" ".*python.*"];
        };
      };
      
      buckets = {
        hardware = lib.mkOption {
          type = lib.types.str;
          default = "hardware";
          description = "InfluxDB bucket for hardware metrics";
        };
        
        processes = lib.mkOption {
          type = lib.types.str;
          default = "processes";
          description = "InfluxDB bucket for process metrics";
        };
      };
    };
  };

  config = lib.mkIf telegrafEnabled {
    services.telegraf = {
      enable = true;
      environmentFiles = ["/run/secrets_derived/influxdb.env"];
      extraConfig = {
        agent = baseAgentConfig;
        
        inputs = hardwareInputs // processInputs;
        
        outputs = 
          # Single file output for all metrics
          {
            file = {
              files = ["/tmp/influx_metrics.out"];
              rotation_max_size = "5MB";
              rotation_max_archives = 10;
            };
            
            # InfluxDB outputs - use array format for multiple outputs
            influxdb_v2 = 
              # Hardware metrics output
              (lib.optionals cfg.hardware-metrics.enable [{
                urls = ["https://influx.jonboh.dev"];
                token = "$INFLUXDB_TOKEN";
                organization = "jonboh";
                bucket = cfg.buckets.hardware;
                # Exclude process metrics from hardware bucket
                namedrop = lib.optionals cfg.process-metrics.enable ["procstat*"];
              }])
              ++
              # Process metrics output  
              (lib.optionals cfg.process-metrics.enable [{
                urls = ["https://influx.jonboh.dev"];
                token = "$INFLUXDB_TOKEN";
                organization = "jonboh";
                bucket = cfg.buckets.processes;
                # Only process metrics in this output
                namepass = ["procstat*"];
              }]);
          };
      };
    };

    systemd.services.telegraf = {
      after = ["derived-secrets.service"];
      wants = ["derived-secrets.service"];
      serviceConfig = {
        # Keep retrying if failed to start
        StartLimitBurst = 10000;
        Restart = lib.mkForce "always";
        RestartSec = "5s";
      };
    };

    systemd.services.derived-secrets = {
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
    
    sops.secrets.influxdb-token = {
      format = "binary";
      sopsFile = self.inputs.nixos-config-sensitive + /secrets/influxdb-token;
      restartUnits = ["derived-secrets.service" "telegraf.service"];
    };
  };
}