{
  pkgs,
  sensitive,
  ...
}: {
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

  # NOTE: see https://github.com/moonlight-stream/moonlight-qt/issues/1409 for issue on modern wayland!
  services.displayManager.gdm.enable = true;
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "jonboh";
  services.desktopManager.gnome.enable = true;

  # To disable installing GNOME's suite of applications
  # and only be left with GNOME shell.
  services.gnome.core-apps.enable = false;
  services.gnome.core-developer-tools.enable = false;
  services.gnome.games.enable = false;
  environment.gnome.excludePackages = with pkgs; [gnome-tour gnome-user-docs];

  programs.xwayland.enable = true;

  networking = {
    hostName = "palantir";
    networkmanager.enable = true;
    firewall = {
      enable = true;
    };
    # wireless = {
    #   enable = true;
    #   # fallbackToWPA2 = false;
    #   secretsFile = config.sops.templates.charon_psk.path;
    #
    #   networks."charon".pskRaw = "ext:psk_charon";
    # };
    # TODO: fix configuration, wlan0 does not seem to work unless
    interfaces = {
      end0 = {
        useDHCP = true;
        ipv4.addresses = [
          {
            address = sensitive.network.ip.palantir.lab;
            prefixLength = 24;
          }
        ];
      };
      # wlan0 = {
      #   useDHCP = true;
      # };
    };
    extraHosts = ''
      ${sensitive.network.ip.tars.lab} tars.lan
    ''; # actually needed to make samba work without timeouts due to missing DNS/Gateway on tars
  };

  # Environment variables for hardware acceleration
  environment.variables = {
    # Force Wayland for proper video acceleration
    QT_QPA_PLATFORM = "wayland";
  };

  # Hardware acceleration and video support
  hardware = {
    graphics = {
      enable = true;
      # VA-API for hardware acceleration
      extraPackages = with pkgs; [
        rpi.libva
        rpi.libva-utils
        # Raspberry Pi VA-API driver
      ];
    };
  };
  # Enable V4L2 video acceleration with request API
  boot.kernelModules = [
    "bcm2835-codec"
    "bcm2835-v4l2"
    "v4l2_mem2mem"
    "rpivid_hevc"
  ];

  # Add user to video group for hardware access
  users.users.jonboh.extraGroups = ["video" "render"];

  environment.systemPackages = with pkgs; [
    (rpi.moonlight-qt.override {
      ffmpeg = rpi.ffmpeg-full;
      inherit libplacebo;
    })
  ];

  system.stateVersion = "24.11";
}
