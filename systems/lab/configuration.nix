{
  pkgs,
  lib,
  sensitive,
  config,
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
    ./kiwix
  ];

  jonboh = {
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
    services.kiwix-serve = {
      enable = true;
      listenAddress = null;
      port = 8888;
      zimPaths = let
        mkVersionedHttpZim = pkgs.callPackage ./kiwix/mkVersionedHttpZim.nix {};
        archlinux = import ./kiwix/archlinux.nix {inherit mkVersionedHttpZim;};
        post-disaster_en = import ./kiwix/post-disaster-en.nix {inherit mkVersionedHttpZim;};
        # post-disaster_es = import ./kiwix/post-disaster-es.nix {inherit mkVersionedHttpZim;};
        devdocs = import ./kiwix/devdocs.nix {inherit mkVersionedHttpZim;};
        pulled_devdocs_zimPaths = lib.mapAttrsToList (name: value: value.zimPath) devdocs;
      in
        [
          archlinux.zimPath
          post-disaster_en.zimPath
          # post-disaster_es.zimPath
        ]
        ++ pulled_devdocs_zimPaths;
    };
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

  services.nginx.virtualHosts."kiwix.jonboh.dev" = {
    forceSSL = true;
    sslCertificate = "/var/lib/acme/jonboh.dev/fullchain.pem";
    sslCertificateKey = "/var/lib/acme/jonboh.dev/key.pem";
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.jonboh.services.kiwix-serve.port}";
      recommendedProxySettings = true;
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
