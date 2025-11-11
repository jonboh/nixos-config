{
  self,
  pkgs,
  config,
  sensitive,
  ...
}: let
  minimal_packagse = import ../common/minimal_packages.nix pkgs;
  common_packages = import ../common/packages.nix pkgs;
in {
  # TODO: add grub.configurationLimit to avoid filling up /boot
  imports = [
    ../common/configuration.nix
    ../common/timers.nix
    ./hardware-configuration.nix
    ./filesystems.nix
    ./sops.nix
    ./samba-mounts.nix
    ./builders.nix
    ./network.nix
    ./gaming.nix
  ];

  configure = {
    wireguard = {
      enable = true;
      deviceName = "workstation";
      allowedNetworks = ["viae"];
      keepAlive = false;
    };
    hardware-metrics = {
      enable = true;
      temperature.enable = true;
    };
  };
  nix = {
    settings = {
      trusted-substituters = [
        "ssh://lab.lan"
      ];
    };
  };
  # system.nixos.label = "GrubStyle";
  # Bootloader.
  boot.loader = {
    efi.canTouchEfiVariables = true;
    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      fsIdentifier = "label";
    };
  };

  nix.settings = {
    secret-key-files = ["/var/secrets/workstation-key"];
    auto-optimise-store = true;
    min-free = 512 * 1024 * 1024;
    max-free = 1024 * 1024 * 1024;
  };

  # syncthing
  services = {
    mullvad-vpn = {
      enable = true;
      enableExcludeWrapper = false;
    };

    usbmuxd.enable = true;

    syncthing = {
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
          "wsl" = {
            id = sensitive.ids.syncthing-wsl;
          };
          "laptop" = {
            id = sensitive.ids.syncthing-laptop;
          };
          "lab" = {
            id = sensitive.ids.syncthing-lab;
          };
        };
        folders = {
          "newsboat-state" = {
            path = "/home/jonboh/.local/share/newsboat";
            devices = [
              "tars"
              "laptop"
            ];
            type = "sendreceive";
          };
          "devel" = {
            path = "/home/jonboh/devel";
            devices = ["tars"];
            type = "sendreceive";
          };
          "vault" = {
            path = "/mnt/storage/vault";
            devices = ["tars" "laptop" "phone" "wsl" "lab"];
            type = "sendreceive";
          };
          "doc" = {
            path = "/mnt/storage/doc";
            devices = ["tars"];
            type = "sendonly";
          };
          "books" = {
            path = "/mnt/storage/books";
            devices = ["tars" "laptop" "phone" "lab"];
            type = "sendreceive";
          };
          "phone_camera" = {
            path = "/mnt/storage/phone_camera";
            devices = ["phone" "tars"];
            type = "receiveonly";
            ignoreDelete = true;
          };
          "phone_whatsapp" = {
            path = "/mnt/storage/phone_camera";
            devices = ["phone" "tars"];
            type = "receiveonly";
            ignoreDelete = true;
          };
        };
      };
    };
    clamav = {
      daemon.enable = true;
      updater.enable = true;
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs;
    [
      ## Applications
      kicad
      qbittorrent
      discord
      digikam
      exiftool # digikam needs it and its makeBinPath does not seem to work correctly
      thunderbird
      orca-slicer
      remmina
      borgbackup
      supersonic
      picard
      feishin
      config.hardware.nvidia.package.settings
    ]
    ++ minimal_packagse
    ++ common_packages;

  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  services.ollama.acceleration = "cuda";

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  services.nextjs-ollama-llm-ui = {
    enable = true;
  };
  services.ollama = {
    enable = true;
  };

  programs.ccache = {
    enable = true;
    cacheDir = "/var/cache/ccache";
  };
  nix.settings.extra-sandbox-paths = [config.programs.ccache.cacheDir];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
