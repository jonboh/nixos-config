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
  };
  security.sudo.wheelNeedsPassword = false;

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

  # List packages installed in system profile. To search, run:
  environment.systemPackages = with pkgs;
    [
      obs-studio
      kicad
    ]
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

        KexAlgorithms = [
          "sntrup761x25519-sha512@openssh.com"
          "curve25519-sha256"
          "curve25519-sha256@libssh.org"
          "ecdh-sha2-nistp256"
          "ecdh-sha2-nistp384"
          "ecdh-sha2-nistp521"
          "diffie-hellman-group-exchange-sha256"
          "diffie-hellman-group16-sha512"
          "diffie-hellman-group18-sha512"
          "diffie-hellman-group14-sha256"
        ];
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
