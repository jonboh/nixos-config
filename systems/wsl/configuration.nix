{
  pkgs,
  sensitive,
  ...
}: {
  imports = [
    # ./docker.nix
    ../../modules
    # NOTE: there are some common configurations in workstations/default.nix that are not applicable to
    # wsl machines (pipewire audio for example)
    ../common/base.nix
    ../common/workstations/nix-ld.nix
    ./sops.nix
  ];

  wsl = {
    enable = true;
    defaultUser = "jonboh";
  };

  users.users.jonboh.shell = pkgs.zsh;

  environment.sessionVariables = {
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";
    XDG_BIN_HOME = "$HOME/.local/bin"; # Not officially in the specification
    VAULT_LOCATION = "$HOME/vault";
    VISUAL = "nixvim-light";
    EDITOR = "nixvim-light";
    # TERM = "kitty"; TODO: kitty on windows?
  };
  programs.zsh.enable = true;
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
  documentation = {
    enable = true;
    doc.enable = true;
    dev.enable = true;
    info.enable = true;
    man = {
      enable = true;
      generateCaches = true;
    };
  };

  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    user = "jonboh";
    dataDir = "/home/jonboh/.syncthingDataDir";
    configDir = "/home/jonboh/.config/syncthing";
    overrideDevices = true;
    overrideFolders = true;
    settings = {
      devices = {
        "tars" = {
          id = sensitive.ids.syncthing-tars;
        };
        "phone" = {
          id = sensitive.ids.syncthing-phone;
        };
        "workstation" = {
          id = sensitive.ids.syncthing-workstation;
        };
        "lab" = {
          id = sensitive.ids.syncthing-lab;
        };
      };
      folders = {
        "vault" = {
          path = "/home/jonboh/vault";
          devices = ["tars" "phone" "workstation"];
          type = "sendreceive";
        };
      };
    };
  };
  environment.pathsToLink = [
    # link all /share and /bin folders from packages into /run/current-system/sw/
    "/share"
    "/bin"
  ];
  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-curses;
    enableSSHSupport = true;
    settings = {
      default-cache-ttl = 3600;
    };
  };
  programs.dconf.enable = true; # for theming home-manager::gtk.enable
  environment.systemPackages = with pkgs; [
    wget
    git
    (pkgs.callPackage ../../scripts/rofi-password-store.nix {keyname = "jon@jonboh.dev";})
    (pkgs.callPackage ../../scripts/pass-password.nix {keyname = "jon@jonboh.dev";})
    gnupg
    pinentry-curses
    neovim
    nixvim
    nixvim-light
    ripgrep
    starship
    man-pages
    eza

    manix
    man-pages
    man-pages-posix
    tldr
    bat
    bat-extras.batdiff
    bat-extras.batman
    bat-extras.prettybat
    bat-extras.batpipe
    bat-extras.batwatch
    dust
    fd
    ripgrep
    lsof
    p7zip
    zip
    tree
    unzip
    gzip
    jq
    (pkgs.callPackage ../../scripts/macho.nix {})
    kitty
    xclip
  ];

  system.stateVersion = "24.05";
}
