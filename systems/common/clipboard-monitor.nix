{pkgs, ...}: {
  systemd.user.services.clipboard-monitor = {
    enable = true;
    description = "Clipboard Monitor/Auto-clearer";
    after = ["graphical-session.target"];
    wantedBy = ["graphical-session.target"];
    path = [pkgs.xclip];

    serviceConfig = {
      ExecStart = "${pkgs.python3}/bin/python3 ${../../scripts/clipboard-monitor.py}";
      Restart = "on-failure";
      Environment = "DISPLAY=:0";
    };
  };
}
