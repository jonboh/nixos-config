{
  self,
  config,
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
    ./sops.nix
  ];

  configure = {
    wireguard = {
      enable = true;
      deviceName = "laptop";
      allowedNetworks = ["viae"];
    };
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
    persistent = true;
    randomizedDelaySec = "30min";
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

  # Enable networking
  networking.hostName = "laptop";
  networking.networkmanager.enable = true;

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  services.logind.lidSwitch = "ignore";

  services.xserver.xautolock =
    # let
    #   modes = "['flow', 'euler2d']";
    # in
    {
      enable = true;
      time = 5;
      # NOTE: does not work because we are not running a shell for the substitutions
      # locker = ''${pkgs.xlockmore}/bin/xlock -font fixed -delay 10000 -mode $(${pkgs.python3}/bin/python -c "import random; print(random.choice(${modes}))", end=''')'';
      locker = ''${pkgs.xlockmore}/bin/xlock -font fixed -mode flow -delay 10000'';
    };

  services = {
    syncthing = {
      enable = true;
      user = "jonboh";
      dataDir = "/home/jonboh/.syncthingDataDir";
      configDir = "/home/jonboh/.config/syncthing";
      overrideDevices = true;
      overrideFolders = true;
      openDefaultPorts = true;
      settings = {
        devices = {
          "tars" = {
            id = sensitive.ids.syncthing-tars;
          };
          "workstation" = {
            id = sensitive.ids.syncthing-workstation;
          };
          "phone" = {
            id = sensitive.ids.syncthing-phone;
          };
          "wsl" = {
            id = sensitive.ids.syncthing-wsl;
          };
        };
        folders = {
          "newsboat-state" = {
            path = "/home/jonboh/.local/share/newsboat";
            devices = [
              "tars"
              "workstation"
            ];
            type = "sendreceive";
          };
          "books" = {
            path = "/home/jonboh/books";
            devices = ["tars" "workstation" "phone"];
            type = "sendreceive";
          };
          "vault" = {
            path = "/home/jonboh/vault";
            devices = ["tars" "workstation" "phone" "wsl"];
            type = "sendreceive";
          };
        };
      };
    };
  };

  environment.systemPackages = with pkgs;
    [
      openfortivpn
      openfortivpn-webview-qt
      mariadb # for dadbod
    ]
    ++ minimal_packagse
    ++ common_packages;

  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = ["jonboh"];
  boot.kernelParams = ["kvm.enable_virt_at_load=0"];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
