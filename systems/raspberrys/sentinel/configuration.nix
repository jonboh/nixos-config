{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../common/configuration.nix
    ./filesystems.nix
    ./sops.nix
    ./rp-configtxt.nix
    ./network.nix
    ./suricata.nix
    ./kernel.nix
  ];
  boot.loader.raspberryPi.bootloader = lib.mkForce "kernel";

  systemd.services.rp-fancontrol = {
    enable = true;
    description = "RPi GPIO fan control service";
    after = ["multi-user.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      ExecStart = "${pkgs.rp-fancontrol}/bin/rp-fancontrol --temp 50 --pwm 0 --temp 55 --pwm 0.5 --temp 60 --pwm 0.7 --temp 70 --pwm 1";
      Type = "simple";
      Restart = "always";
      RestartSec = "5";
    };
  };

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
  services.vector.settings.sinks.loki_eve = {
    type = "loki";
    inputs = ["eve_json"];
    endpoint = "https://loki.jonboh.dev";
    encoding = {codec = "json";};
    labels.source = "eve_json";
  };

  environment.systemPackages = with pkgs; [
    emacs
    git
    wget
    tcpdump
  ];

  system.stateVersion = "24.11";
}
