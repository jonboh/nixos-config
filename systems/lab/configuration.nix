{
  pkgs,
  sensitive,
  ...
}: let
  minimal_packagse = import ../common/minimal_packages.nix pkgs;
  common_packages = import ../common/packages.nix pkgs;
in {
  imports = [
    ../common/configuration.nix
    ../common/timers.nix
    ./hardware-configuration.nix
    ./filesystems.nix
    ./samba-mounts.nix
    ./sops.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  nix.gc = {
    automatic = true;
    persistent = true;
  };

  zramSwap = {
    enable = true;
    priority = 5;
  };
  swapDevices = [
    {
      size = 8 * 1024;
      priority = 10;
      device = "/var/lib/swapfile";
      randomEncryption.enable = true;
    }
  ];

  # Enable networking
  networking = {
    hostName = "lab"; # Define your hostname.
    wireless.enable = false;
    interfaces = {
      enp10s0 = {
        useDHCP = false;
        ipv4.addresses = [
          {
            address = sensitive.network.ip.lab;
            prefixLength = 24;
          }
        ];
      };
    };
    defaultGateway = sensitive.network.gateway "lab";
    nameservers = [(sensitive.network.dns-server "lab")];
    dhcpcd.enable = false;

    networkmanager.enable = true;
  };

  # List packages installed in system profile. To search, run:
  environment.systemPackages = with pkgs;
    [obs-studio]
    ++ minimal_packagse
    ++ common_packages;

  services = {
    openssh = {
      enable = true;
      allowSFTP = true;
      openFirewall = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = pkgs.lib.mkForce "no";
        ClientAliveInterval = 10;
        ClientAliveCountMax = 3;
      };
    };
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
          # "devel" = {
          #   path = "/home/jonboh/devel";
          #   devices = ["tars"];
          #   type = "sendreceive";
          # };
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
  users.users.jonboh.openssh.authorizedKeys.keys = [
    sensitive.keys.ssh.workstation
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
