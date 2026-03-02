{
  pkgs,
  config,
  sensitive,
  ...
}: {
  # TODO: add grub.configurationLimit to avoid filling up /boot
  imports = [
    ../common/workstations
    ../common/workstations/optionals/timers.nix
    ./hardware-configuration.nix
    ./filesystems.nix
    ./sops.nix
    ./samba-mounts.nix
    ./network.nix
    ./gaming.nix
    ./tablet.nix
    ./builders.nix
  ];

  jonboh.configure = {
    ntpd-rs.enable = true;
    wireguard = {
      enable = true;
      deviceName = "workstation";
      allowedNetworks = ["viae"];
      keepAlive = false;
    };
    telegraf-metrics = {
      enable = true;
      hardware-metrics = {
        enable = true;
        temperature.enable = true;
      };
      process-metrics.enable = true;
    };
    vector-logging.enable = true;
  };
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
    secret-key-files = ["/var/secrets/workstation.jonboh.dev-0"];
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
            id = sensitive.ids.syncthing.tars;
          };
          "phone" = {
            id = sensitive.ids.syncthing.phone;
          };
          "wsl" = {
            id = sensitive.ids.syncthing.wsl;
          };
          "laptop" = {
            id = sensitive.ids.syncthing.laptop;
          };
          "lab" = {
            id = sensitive.ids.syncthing.lab;
          };
        };
        folders = {
          "vault" = {
            path = "/mnt/storage/vault";
            devices = ["tars" "laptop" "phone" "wsl" "lab"];
            type = "sendreceive";
          };
          "books" = {
            path = "/mnt/storage/books";
            devices = ["tars" "laptop" "phone" "lab"];
            type = "sendreceive";
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
  environment.systemPackages = with pkgs; [
    ## Applications
    kicad
    qbittorrent
    discord
    thunderbird
    orca-slicer
    remmina
    borgbackup
    picard
    freecad
    samba
    (pkgs.callPackage ../../scripts/shpool-list-all.nix {})
    (pkgs.callPackage ../../scripts/ping-devices.nix {inherit sensitive;})
  ];

  environment.shellAliases = {
    spl = "shpool-list-all";
  };

  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  #   services.nextjs-ollama-llm-ui = {
  #     enable = true;
  #   };
  #   services.ollama = {
  #     enable = true;
  # acceleration = "cuda";
  #   };

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
