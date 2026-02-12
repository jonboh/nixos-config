{
  self,
  config,
  lib,
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

  # services.desktopManager.cosmic.enable = true;
  # services.displayManager.autoLogin = {
  #   enable = true;
  #   # Replace `yourUserName` with the actual username of user who should be automatically logged in
  #   user = "jonboh";
  # };

  # services.xserver.enable = true;
  # # Enable Plasma
  # services.desktopManager.plasma6.enable = true;
  #
  # # Default display manager for Plasma
  # services.displayManager.sddm = {
  #   enable = true;
  #
  #   # To use Wayland (Experimental for SDDM)
  #   # wayland.enable = true;
  # };
  services.displayManager.gdm.enable = true;
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
    # Let VA-API auto-detect the driver instead of forcing v4l2_request
    # LIBVA_DRIVER_NAME will be auto-detected
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
  # boot.kernelModules = [
  #   "bcm2835-codec"
  #   "bcm2835-v4l2"
  #   "v4l2_mem2mem"
  #   "videodev"
  #   # V4L2 request API modules
  #   "hantro_vpu"
  #   "rpi_hevc_dec"
  #   # Video core modules
  #   "vc4"
  #   "v3d"
  #
  #   ## from raspbian
  #
  #   "spi_bcm2835"
  #   "mc"
  #   "videobuf2_common"
  #   "videodev"
  #   "videobuf2_v4l2"
  #   "videobuf2_dma_contig"
  #   "rpivid_hevc"
  # ];
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
    kitty
    # mesa
    rpi.ffmpeg-full
    rpi.libva
    rpi.libva-utils
    rpi.v4l-utils
    # # Additional packages for V4L2 request API
    rpi.libdrm
    # # Linux firmware for video acceleration
    rpi.linux-firmware
    rpi.vulkan-tools
    rpi.virtualgl
    gdb
    bintools
    pkg-config
  ];

  # services.flatpak.enable = true;

  # Execute AppImage binaries with appimage-run
  # boot.binfmt.registrations.appimage = {
  #   wrapInterpreterInShell = false;
  #   interpreter = "${pkgs.appimage-run}/bin/appimage-run";
  #   recognitionType = "magic";
  #   offset = 0;
  #   mask = "\\xff\\xff\\xff\\xff\\x00\\x00\\x00\\x00\\xff\\xff\\xff";
  #   magicOrExtension = "\\x7fELF....AI\\x02";
  # };
  system.stateVersion = "24.11";
  # NOTE: see https://github.com/moonlight-stream/moonlight-qt/issues/1409 for issue on modern wayland!
}
