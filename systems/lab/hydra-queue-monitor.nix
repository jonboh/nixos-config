{pkgs, ...}: {
  systemd.services.hydra-queue-monitor = {
    description = "Monitor Hydra queue runner and restart if needed";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = "${pkgs.python3}/bin/python3 ${./hydra-queue-monitor.py}";
      StandardOutput = "journal";
      StandardError = "journal";
    };
    # Ensure the hydra service is available
    after = ["hydra-server.service"];
    wants = ["hydra-server.service"];
  };

  systemd.timers.hydra-queue-monitor = {
    enable = true;
    description = "Run Hydra queue monitor every 5 minutes";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "*:0/5"; # Every 5 minutes
      Persistent = true; # Run missed timers on boot
      RandomizedDelaySec = 30; # Add some randomization to avoid exact timing
    };
  };
}
