{
  self,
  pkgs,
  sensitive,
  lib,
  modulesPath,
  ...
}: {
  imports = [
    ./nix-ld.nix
    ./tablet.nix
    ./clipboard-monitor.nix
    # "${modulesPath}/virtualisation/qemu-vm.nix" # activate if you want to generate vms
  ];

  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      trusted-users = ["root" "@wheel"];
      trusted-public-keys = [
        sensitive.keys.nix.workstation
        sensitive.keys.nix.brick
        sensitive.keys.nix.tars
        sensitive.keys.nix.forge
        sensitive.keys.nix.hydra-lab
      ];
    };
    package = pkgs.nixVersions.latest;
    registry = {
      # NOTE: see https://discourse.nixos.org/t/do-flakes-also-set-the-system-channel/19798/2
      nixpkgs.flake = self.inputs.nixpkgs;
      unstable.flake = self.inputs.nixpkgs-unstable;
    };
  };

  time.timeZone = "Europe/Madrid";

  boot.supportedFilesystems = ["ntfs"];

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "es_ES.UTF-8";
    LC_IDENTIFICATION = "es_ES.UTF-8";
    LC_MEASUREMENT = "es_ES.UTF-8";
    LC_MONETARY = "es_ES.UTF-8";
    LC_NAME = "es_ES.UTF-8";
    LC_NUMERIC = "es_ES.UTF-8";
    LC_PAPER = "es_ES.UTF-8";
    LC_TELEPHONE = "es_ES.UTF-8";
    LC_TIME = "es_ES.UTF-8";
  };

  environment.sessionVariables = {
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";
    XDG_BIN_HOME = "$HOME/.local/bin"; # Not officially in the specification
    VAULT_LOCATION = "$HOME/vault";
    VISUAL = "nixvim-light";
    EDITOR = "nixvim-light";
    TERM = "kitty";
    PATH = ["$XDG_BIN_HOME"];
  };

  xdg = {
    portal = {
      enable = true;
      # this makes possible to use nnn as a file chooser through xdg-portals
      # although, for some reason, it is incompatible with pkgs.xdg-desktop-portal-gtk,
      # which makes it to just use gtk instead of termfilechooser
      extraPortals = [pkgs.xdg-desktop-portal-termfilechooser pkgs.xdg-desktop-portal-gtk];
      # xdgOpenUsePortal = true;
      config = {
        common = {
          default = ["none"];
          "org.freedesktop.impl.portal.FileChooser" = ["termfilechooser"];
        };
      };
    };
    mime.defaultApplications = {
      "text/html" = "librewolf.desktop";
      "x-scheme-handler/http" = "librewolf.desktop";
      "x-scheme-handler/https" = "librewolf.desktop";
      "x-scheme-handler/about" = "librewolf.desktop";
      "x-scheme-handler/unknown" = "librewolf.desktop";
      "x-scheme-handler/file" = "file-handler.desktop";
      "inode/directory" = "yazi.desktop";
      "inode/x-trash" = "yazi.desktop";
      "x-directory/normal" = "yazi.desktop";
      "application/pdf" = "pdf-handler.desktop";
      # Image
      "image/jpeg" = "nsxiv.desktop";
      "image/png" = "nsxiv.desktop";
      "image/gif" = "nsxiv.desktop";
      "image/svg+xml" = "nsxiv.desktop";
      "image/bmp" = "nsxiv.desktop";
      "image/x-xpixmap" = "nsxiv.desktop";
      "image/tiff" = "nsxiv.desktop";
      "image/webp" = "nsxiv.desktop";
      # Video
      "video/x-matroska" = "io.mpv.Mpv.desktop";
      "video/mp4" = "io.mpv.Mpv.desktop";
      "video/mpeg" = "io.mpv.Mpv.desktop";
      "video/quicktime" = "io.mpv.Mpv.desktop";
      "video/webm" = "io.mpv.Mpv.desktop";
      "video/x-msvideo" = "io.mpv.Mpv.desktop";
      "video/x-ms-wmv" = "io.mpv.Mpv.desktop";
      "video/avi" = "io.mpv.Mpv.desktop";
      "video/flv" = "io.mpv.Mpv.desktop";
      "video/x-flv" = "io.mpv.Mpv.desktop";
      "video/3gpp" = "io.mpv.Mpv.desktop";
      "video/3gpp2" = "io.mpv.Mpv.desktop";
      "video/x-m4v" = "io.mpv.Mpv.desktop";
      # 3dprinting
      # "model/stl" = "PrusaSlicerSingleInstance.desktop";
    };
  };

  # Execute AppImage binaries with appimage-run
  boot.binfmt.registrations.appimage = {
    wrapInterpreterInShell = false;
    interpreter = "${pkgs.appimage-run}/bin/appimage-run";
    recognitionType = "magic";
    offset = 0;
    mask = "\\xff\\xff\\xff\\xff\\x00\\x00\\x00\\x00\\xff\\xff\\xff";
    magicOrExtension = "\\x7fELF....AI\\x02";
  };

  programs.dconf.enable = true; # for theming home-manager::gtk.enable

  services.displayManager = {
    defaultSession = "none+i3";
    autoLogin = {
      enable = true;
      user = "jonboh";
    };
  };
  services.xserver = {
    enable = true;
    desktopManager.xterm.enable = false;
    displayManager = {
      lightdm.background = "#000000";
      sessionCommands = ''
        xset r rate 175 60
      '';
    };

    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        rofi
        i3status-rust
        i3lock
      ];
    };
    autoRepeatDelay = 175;
    autoRepeatInterval = 60;
    # Configure keymap in X11
    xkb = {
      variant = "";
      layout = "us";
    };
  };
  services.gnome.gnome-keyring.enable = true;

  programs.zsh.enable = true;
  programs.nix-index.enableBashIntegration = false;
  programs.nix-index.enableZshIntegration = false;

  users.users.jonboh = {
    isNormalUser = true;
    description = "jonboh";
    extraGroups = ["networkmanager" "wheel" "vboxusers" "dialout"];
    shell = pkgs.zsh;
  };

  systemd.services.ulpdactyl_status = let
    python = pkgs.python3.withPackages (ps: [ps.hid]);
  in {
    enable = true;
    enableStrictShellChecks = true;
    path = [pkgs.procps];
    wantedBy = ["multi-user.target"]; # This should ensure the service gets started correctly
    serviceConfig = {
      ExecStart = "${python}/bin/python ${../../extra_configs/i3/keyboard_status_server.py}";
      Restart = "always";
      RestartSec = "5";
      User = "root";
    };
  };

  # Enable automatic login for the user.
  services.getty.autologinUser = "jonboh";

  networking.firewall.enable = true;
  environment.etc.hosts.mode = "0644"; # NOTE: this makes hosts mutable at runtime, allowing dynamic blocking

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
    # (nerdfonts.override {fonts = ["FiraCode" "DroidSansMono"];})
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
  ];
  fonts.fontconfig = {
    defaultFonts = {
      emoji = ["Noto Color Emoji"];
      monospace = [
        "Noto Sans Mono"
        "emoji" # NOTE: adding emoji to the other default prevents the wrong font from being used in some cases, see: https://github.com/NixOS/nixpkgs/issues/172412
      ];
      sansSerif = [
        "Noto Sans"
        "emoji"
      ];
      serif = [
        "Noto Serif"
        "emoji"
      ];
    };
  };

  security.rtkit.enable = true; # this is used by PipeWire for realtime priority
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  services.udisks2.enable = true; # for udiskie

  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  documentation = {
    enable = true;
    doc.enable = true;
    dev.enable = true;
    info.enable = true;
    man = {
      enable = true;
      generateCaches = false; # i dont use apropos
    };
  };
  environment.pathsToLink = [
    # link all /share and /bin folders from packages into /run/current-system/sw/
    "/share"
    "/bin"
  ];

  # List services that you want to enable:

  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-curses;
    enableSSHSupport = true;
    settings = {
      default-cache-ttl = 10800;
    };
  };
}
