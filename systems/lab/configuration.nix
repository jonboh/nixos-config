{
  pkgs,
  sensitive,
  ...
}: {
  imports = [
    ../common/workstations
    ../common/servers.nix
    ./hardware-configuration.nix
    ./filesystems.nix
    ./samba-mounts.nix
    ./sops.nix
    ./builders.nix
    ./hydra.nix
    ./network.nix
    ./immich.nix
  ];

  configure = {
    ntpd-rs.enable = true;
    hardware-metrics = {
      enable = true;
      temperature.enable = true;
    };
    wireguard = {
      enable = true;
      deviceName = "lab";
      allowedNetworks = ["viae" "hodos"];
      keepAlive = true;
    };
    vector-logging.enable = true;
  };
  security.sudo.wheelNeedsPassword = false;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  nix.gc = {
    automatic = true;
    persistent = true;
  };

  zramSwap = {
    enable = true;
    priority = 20;
  };
  swapDevices = [
    {
      size = 8 * 1024;
      priority = 10;
      device = "/var/lib/swapfile";
      randomEncryption.enable = true;
    }
  ];

  environment.systemPackages = with pkgs; [
    obs-studio
    kicad
  ];

  services = {
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
          "workstation" = {
            id = sensitive.ids.syncthing-workstation;
          };
        };
        folders = {
          "vault" = {
            path = "/home/jonboh/vault";
            devices = ["tars" "laptop" "phone" "wsl" "workstation"];
            type = "sendreceive";
          };
          "books" = {
            path = "/home/jonboh/books";
            devices = ["tars" "laptop" "phone"];
            type = "sendreceive";
          };
        };
      };
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
