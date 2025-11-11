pkgs: let
  focus-network = pkgs.callPackage ../../scripts/focus-network-wrapped.nix {};
  unfocus-network = pkgs.callPackage ../../scripts/unfocus-network-wrapped.nix {};
  focus-network-entry = pkgs.makeDesktopItem {
    name = "focus-network";
    exec = ''${focus-network}/bin/focus-network''; # Points to the location of the binary
    type = "Application";
    desktopName = "Focus Network";
    genericName = "Focus Network";
    comment = "Block domains";
    categories = ["Utility"];
    icon = "utilities-terminal"; # Make sure this icon name is valid or provide a path to an icon file
  };
  unfocus-network-entry = pkgs.makeDesktopItem {
    name = "unfocus-network";
    exec = ''${unfocus-network}/bin/unfocus-network''; # Points to the location of the binary
    type = "Application";
    desktopName = "Unfocus Network";
    genericName = "Unfocus Network";
    comment = "Unblock domains";
    categories = ["Utility"];
    icon = "utilities-terminal"; # Make sure this icon name is valid or provide a path to an icon file
  };
in
  with pkgs; [
    ## Audio
    audacity
    wireplumber
    helvum
    playerctl # for play/pause media keys

    ## Security
    (pkgs.callPackage ../../scripts/rofi-password-store.nix {keyname = "jon@jonboh.dev";})
    (pkgs.callPackage ../../scripts/pass-password.nix {keyname = "jon@jonboh.dev";})
    gnupg
    pinentry-curses
    openssl
    age
    sops

    ## System Utilities
    xdragon
    sysz
    libnotify
    sshfs
    dnsutils
    usbutils
    pv

    picocom # for uart

    ## Networking
    nmap
    ldns

    ## Browsing
    firefox
    ungoogled-chromium

    ## Development
    gcc
    clang
    gnumake
    ninja
    cmake
    llvm
    neovim
    nixvim
    nixvim-light
    wezterm
    rr
    pkg-config
    alejandra

    ## Debugging
    gdb
    unstable.vscode-extensions.ms-vscode.cpptools # for neovim dap
    unstable.vscode-extensions.vadimcn.vscode-lldb # for neovim dap

    ### Python
    (python3.withPackages (ps: [
      ps.adblock
      ps.debugpy
      ps.ipython
      ps.pandas
      ps.matplotlib
      ps.numpy
      ps.scipy
      ps.scikit-learn
    ]))
    pyright

    julia

    ## Utilities
    gzip
    jq
    fq
    nix-tree
    (pkgs.callPackage ../../scripts/ffnnn.nix {})
    (pkgs.callPackage ../../scripts/zen-mode.nix {})
    (pkgs.callPackage ../../scripts/killselect.nix {})
    (pkgs.callPackage ../../scripts/pdf_handler.nix {})
    man-pages
    man-pages-posix
    tldr
    bat
    bat-extras.batdiff
    bat-extras.batman
    bat-extras.prettybat
    bat-extras.batpipe
    bat-extras.batwatch
    du-dust
    just
    fd
    ripgrep
    lsof
    p7zip
    zip
    tree
    unrar
    unzip
    rofimoji
    trash-cli
    direnv
    viu
    nsxiv
    shai
    distrobox
    nnn
    lm_sensors
    sqlite
    focus-network
    unfocus-network
    focus-network-entry
    unfocus-network-entry

    # for yazi lsar
    unar
    (pkgs.callPackage ../../packages/allmytoes.nix {}) # for thumbnail generation in yazi
    (pkgs.callPackage ../../packages/simple-thumbnailer-stl/package.nix {})

    ## News
    newsboat

    ## Documents
    libreoffice
    texlive.combined.scheme-full

    ## Video & Image
    ffcast
    ffmpeg
    unstable.mpv # unstable to fix yt-dlp version with incorrect format requests
    pavucontrol
    alsa-utils

    ## PDF
    poppler_utils
    zathura
    kdePackages.okular

    ## Applications
    spotify
    feishin
    (pkgs.unstable.anki.withAddons [
      pkgs.unstable.ankiAddons.anki-connect
      ((
          pkgs.unstable.anki-utils.buildAnkiAddon
          (finalAttrs: {
            pname = "open_in_anki_nvim";
            version = "aef8d5bc734fedc2d4e38e8027b8558cfee47c45";
            src = pkgs.fetchFromGitHub {
              owner = "jonboh";
              repo = "open_in_anki_nvim";
              rev = finalAttrs.version;
              hash = "sha256-IU9HLAsVQVx1fE5dlyFo1b+IrBvGoY27OkrZf2BWMgM=";
            };
          })
        ).withConfig {
          config = {
            terminal = "kitty";
            editor = "${pkgs.nixvim}/bin/nixvim";
          };
        })
      # TODO: update to new terminal setup
      # (pkgs.unstable.anki-utils.buildAnkiAddon
      #   (finalAttrs: {
      #     pname = "anki-open-vault-reference";
      #     version = "0.0.0";
      #     src = fetchFromGitHub {
      #       owner = "jonboh";
      #       repo = "anki-open-vault-reference";
      #       rev = "c7cb178c0d8659a8ee596f0b25f5f41bb9391da5";
      #       sha256 = "sha256-TNAcbckhdDE8P35uMW48zIg4uB4JISdMQ3TT2Qu47Ig=";
      #     };
      #   }))
      (pkgs.unstable.anki-utils.buildAnkiAddon
        (finalAttrs: {
          pname = "Anki-StylusDraw";
          version = "a197a6da0f2fc31e2f1117378a95e003fe5c644f";
          src = fetchFromGitHub {
            owner = "Rytisgit";
            repo = "Anki-StylusDraw";
            rev = finalAttrs.version;
            sha256 = "sha256-XHB0AvFG2UYBvCM9y4wupkHekoOQWvancLdBcasoG5Q=";
          };
          sourceRoot = "source/AnkiDraw";
        }))
    ])
    drawpile
    krita
    (pkgs.callPackage ../../scripts/krita-fzf.nix {})
    (pkgs.callPackage ../../scripts/single_display.nix {})
    (pkgs.callPackage ../../scripts/single_display1080.nix {})
    (pkgs.callPackage ../../scripts/dual_display.nix {})
    (pkgs.callPackage ../../scripts/single_display_and_tablet.nix {})
    (pkgs.callPackage ../../scripts/dual_display_and_tablet.nix {})
    (pkgs.callPackage ../../scripts/turn_tablet_off.nix {})
    (pkgs.callPackage ../../scripts/turn_tablet_on.nix {})
    (pkgs.callPackage ../../scripts/turn_tablet_on_mirror_main.nix {})
    (pkgs.callPackage ../../scripts/atuin-export-zsh.nix {})
    (pkgs.callPackage ../../scripts/git-init-tars.nix {})
    (pkgs.callPackage ../../scripts/is_vault_unlocked.nix {})
  ]
