{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.jonboh.configure.vector-logging;
in {
  options.jonboh.configure.vector-logging = {
    enable = mkEnableOption "vector logging with Loki integration";

    lokiEndpoint = mkOption {
      type = types.str;
      default = "https://loki.jonboh.dev";
      description = "Loki endpoint URL";
    };
  };

  config = mkIf cfg.enable {
    services.vector = {
      enable = true;
      journaldAccess = true;
      settings = {
        sources = {
          journald.type = "journald";
          vector_metrics.type = "internal_metrics";
        };

        transforms = {
          add_machine_info = {
            type = "remap";
            inputs = ["journald"];
            source = ''
              .hostname = "${config.networking.hostName}"
            '';
          };

          classify_services = {
            type = "remap";
            inputs = ["add_machine_info"];
            source = ''
              # Extract systemd unit with proper empty string handling
              .unit = "unknown"
              if exists(._SYSTEMD_UNIT) {
                .temp_unit = to_string(._SYSTEMD_UNIT) ?? ""
                if length(.temp_unit) > 0 {
                  .unit = .temp_unit
                }
              }
              if .unit == "unknown" && exists(._SYSTEMD_USER_UNIT) {
                .temp_unit = to_string(._SYSTEMD_USER_UNIT) ?? ""
                if length(.temp_unit) > 0 {
                  .unit = .temp_unit
                }
              }
              if .unit == "unknown" && exists(._COMM) {
                .temp_unit = to_string(._COMM) ?? ""
                if length(.temp_unit) > 0 {
                  .unit = .temp_unit
                }
              }
              if .unit == "unknown" && exists(.SYSLOG_IDENTIFIER) {
                .temp_unit = to_string(.SYSLOG_IDENTIFIER) ?? ""
                if length(.temp_unit) > 0 {
                  .unit = .temp_unit
                }
              }
              # Clean up temp variable
              if exists(.temp_unit) {
                del(.temp_unit)
              }

              # Smart level inference with multiple sources and fallbacks
              # 1. First check if there's already a level field from the application
              .level = if exists(.LEVEL) {
                downcase(to_string(.LEVEL) ?? "")
              } else if exists(.LOG_LEVEL) {
                downcase(to_string(.LOG_LEVEL) ?? "")
              } else if exists(._AUDIT_TYPE_NAME) && contains(downcase(to_string(._AUDIT_TYPE_NAME) ?? ""), "fail") {
                "error"
              } else {
                # 2. Fall back to PRIORITY mapping (syslog standard)
                if .PRIORITY == "0" || .PRIORITY == "1" || .PRIORITY == "2" {
                  "critical"
                } else if .PRIORITY == "3" {
                  "error"
                } else if .PRIORITY == "4" {
                  "warning"
                } else if .PRIORITY == "5" || .PRIORITY == "6" {
                  "info"
                } else if .PRIORITY == "7" {
                  "debug"
                } else {
                  "info"
                }
              }

              # 3. Message-based level enhancement (only if current level is generic)
              .level = if .level == "info" && exists(.message) {
                # Get message content and safely convert to lowercase
                .msg_lower = downcase(.message) ?? ""

                # First check if message has structured log format with explicit level
                # Handle common formats: "TIMESTAMP LEVEL service: message" or just "LEVEL service: message"
                # Examples:
                # - "2025-12-20T10:21:38.727514Z  INFO vector: Vector has started..."
                # - "INFO vector: Vector has started..."
                # - "Dec 20 10:21:38 ERROR nginx: connection failed"
                if match(.msg_lower, r'(^|\s+)(trace|debug)(\s+\w+:|:|\s)') {
                  "debug"
                } else if match(.msg_lower, r'(^|\s+)info(\s+\w+:|:|\s)') {
                  "info"
                } else if match(.msg_lower, r'(^|\s+)(warn|warning)(\s+\w+:|:|\s)') {
                  "warning"
                } else if match(.msg_lower, r'(^|\s+)(error|err)(\s+\w+:|:|\s)') {
                  "error"
                } else if match(.msg_lower, r'(^|\s+)(fatal|critical|crit)(\s+\w+:|:|\s)') {
                  "critical"
                } else {
                  # Fall back to keyword search in message body for unstructured logs
                  if contains(.msg_lower, "error") || contains(.msg_lower, "failed") || contains(.msg_lower, "critical") {
                    "error"
                  } else if contains(.msg_lower, "warn") {
                    "warning"
                  } else if contains(.msg_lower, "debug") {
                    "debug"
                  } else {
                    .level
                  }
                }
              } else {
                .level
              }

              # Clean up temporary variables
              if exists(.msg_lower) {
                del(.msg_lower)
              }
            '';
          };
        };

        sinks = {
          loki = {
            type = "loki";
            inputs = ["classify_services"];
            endpoint = cfg.lokiEndpoint;
            encoding = {codec = "json";};
            labels = {
              hostname = "{{ hostname }}";
              unit = "{{ unit }}";
              level = "{{ level }}";
            };
          };
        };
      };
    };
  };
}
