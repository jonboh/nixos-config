{pkgs, ...}: {
  imports = [
    ../../common/raspberrys.nix
    ./filesystems.nix
    ./sops.nix
    ./network.nix
    ./suricata.nix
  ];

  zramSwap = {
    enable = true;
    priority = 20;
  };
  swapDevices = [
    {
      size = 4 * 1024;
      priority = 10;
      device = "/var/lib/swapfile";
      randomEncryption.enable = true;
    }
  ];

  services = {
    logrotate = {
      enable = true;
      settings = {
        "/var/log/suricata" = {
          frequency = "daily";
          rotate = 4;
          # NOTE: see: https://docs.suricata.io/en/latest/output/log-rotation.html
          postrotate = ''${pkgs.util-linux}/bin/kill -HUP `${pkgs.procps}/bin/pgrep -f suricata 2>/dev/null` 2>/dev/null || true'';
        };
      };
    };
  };

  services.vector.settings.sources.eve_json = {
    type = "file";
    include = ["/var/log/suricata/eve.json"];
    read_from = "beginning";
  };

  services.vector.settings.transforms.classify_suricata = {
    type = "remap";
    inputs = ["eve_json"];
    source = ''
      .hostname = "sentinel"
      .unit = "suricata-eve.json"

      # Extract event type and severity from Suricata JSON
      if exists(.event_type) {
        .event_type = .event_type
      }

      if exists(.alert) {
        .level = "critical"
        .alert_signature = .alert.signature || "unknown"
        .alert_severity = .alert.severity || 1
      } else if exists(.anomaly) {
        .level = "warning"
      } else if exists(.drop) {
        .level = "warning"
      } else {
        .level = "info"
      }
    '';
  };

  services.vector.settings.sinks.loki_eve = {
    type = "loki";
    inputs = ["classify_suricata"];
    endpoint = "https://loki.jonboh.dev";
    encoding = {codec = "json";};
    labels = {
      hostname = "{{ hostname }}";
      unit = "{{ unit }}";
      level = "{{ level }}";
      event_type = "{{ event_type }}";
    };
  };

  environment.systemPackages = with pkgs; [
    emacs
    git
    wget
    tcpdump
  ];

  system.stateVersion = "24.11";
}
