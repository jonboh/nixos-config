{
  pkgs,
  lib,
  sensitive,
  ...
}: let
  moonlight = pkgs.rpi.moonlight-qt.override {
    ffmpeg = pkgs.rpi.ffmpeg-full;
    libplacebo = pkgs.libplacebo;
  };
in {
  imports = [
    ../../common/raspberrys.nix
    ./sops.nix
    ./rp-configtxt.nix
    ./kernel.nix
  ];

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

  services.displayManager.gdm.enable = true;
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "hermes";
  services.desktopManager.gnome.enable = true;
  services.gnome.core-apps.enable = false;
  services.gnome.core-developer-tools.enable = false;
  services.gnome.games.enable = false;
  environment.gnome.excludePackages = with pkgs; [gnome-tour gnome-user-docs];

  # Enable dconf and configure GNOME with 1-minute display timeout
  programs.dconf.enable = true;
  programs.dconf.profiles = let
    displayTurnOffSeconds = 60; # 1 minute
  in {
    user.databases = [
      {
        settings = {
          # Allow logout and power off, but disable user switching
          "org/gnome/desktop/lockdown" = {
            disable-log-out = false; # Allow logout
            disable-user-switching = true; # Keep user switching disabled
            disable-lock-screen = true; # Allow screen lock
          };
          # Configure power management - prevent system sleep/suspend but allow display control
          "org/gnome/settings-daemon/plugins/power" = {
            sleep-inactive-ac-timeout = lib.gvariant.mkUint32 0;
            sleep-inactive-ac-type = "nothing";
            sleep-inactive-battery-timeout = lib.gvariant.mkUint32 0;
            sleep-inactive-battery-type = "nothing";

            sleep-display-ac = lib.gvariant.mkUint32 displayTurnOffSeconds;
            sleep-display-battery = lib.gvariant.mkUint32 displayTurnOffSeconds;
          };
          "org/gnome/desktop/session" = {
            idle-delay = lib.gvariant.mkUint32 displayTurnOffSeconds;
          };
        };
        locks = [
          # Lock user switching setting only
          "/org/gnome/desktop/lockdown/disable-log-out"
          "/org/gnome/desktop/lockdown/disable-user-switching"
          "/org/gnome/desktop/lockdown/disable-lock-screen"
          # Lock power management settings to prevent system suspend
          "/org/gnome/settings-daemon/plugins/power/sleep-inactive-ac-timeout"
          "/org/gnome/settings-daemon/plugins/power/sleep-inactive-ac-type"
          "/org/gnome/settings-daemon/plugins/power/sleep-inactive-battery-timeout"
          "/org/gnome/settings-daemon/plugins/power/sleep-inactive-battery-type"
          # Lock display power management
          "/org/gnome/settings-daemon/plugins/power/sleep-display-ac"
          "/org/gnome/settings-daemon/plugins/power/sleep-display-battery"
          # Lock session idle delay
          "/org/gnome/desktop/session/idle-delay"
        ];
      }
    ];
  };

  # Configure systemd logind to allow power management but prevent automatic actions
  services.logind.settings = {
    Login = {
      # Allow power button to work normally (power off)
      HandlePowerKey = "poweroff";
      # Disable suspend and hibernate
      HandleSuspendKey = "ignore";
      HandleHibernateKey = "ignore";
      HandleLidSwitch = "ignore";
      HandleLidSwitchExternalPower = "ignore";
      # Never automatically logout or suspend due to idle
      IdleAction = "ignore";
      IdleActionSec = "infinity";
    };
  };

  networking = {
    hostName = "palantir";
    networkmanager = {
      enable = true;
      unmanaged = [
        "end0" # NOTE: managed with networkd
      ];
    };
  };

  # Environment variables for hardware acceleration
  environment.variables = {
    # Force Wayland for proper video acceleration
    QT_QPA_PLATFORM = "wayland";
  };

  # Hardware acceleration and video support
  hardware.graphics.enable = true;
  # Enable V4L2 video acceleration with request API
  boot.kernelModules = [
    "bcm2835-codec"
    "bcm2835-v4l2"
    "v4l2_mem2mem"
    "rpivid_hevc"
  ];

  users.users.hermes = {
    isNormalUser = true;
    description = "hermes";
    extraGroups = ["video" "render" "networkmanager"];
    shell = pkgs.bash;
    hashedPassword = sensitive.passwords.hermes;
  };

  environment.systemPackages = [
    pkgs.kitty
    moonlight
  ];

  systemd.user.services.moonlight = {
    enable = true;
    description = "Moonlight Game Streaming Client";
    after = ["graphical-session.target"];
    wants = ["graphical-session.target"];
    wantedBy = ["default.target"];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${lib.getExe moonlight}";
      Restart = "on-failure";
      RestartSec = "5";
      Environment = [
        "WAYLAND_DISPLAY=wayland-0"
        "QT_QPA_PLATFORM=wayland"
      ];
    };
  };

  system.stateVersion = "24.11";
}
