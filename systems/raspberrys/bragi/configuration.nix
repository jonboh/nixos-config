{
  pkgs,
  config,
  sensitive,
  modulesPath,
  ...
}: {
  imports = [
    ../common/configuration.nix
    ../common/telegraf-environment.nix
    ../common/hardware-metrics.nix
    ../common/hardware-rpi4.nix
    ../common/sops.nix
    ./sops.nix
    ./network.nix
    ./navidrome.nix
    ./ftp.nix
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
  ];
  networking.hostName = "bragi";

  security.acme = {
    acceptTerms = true;
    defaults.email = "jon.bosque.hernando@gmail.com";
    certs."jonboh.dev" = {
      domain = "*.jonboh.dev";
      dnsProvider = "rfc2136";
      environmentFile = config.sops.secrets.certs-secrets.path;
      dnsPropagationCheck = false;
      # server = "https://acme-staging-v02.api.letsencrypt.org/directory"; # NOTE: use this for debugging
      validMinDays = 90;
    };
  };

  users.users.nginx.extraGroups = ["acme"];
  services = {
    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedZstdSettings = true;
      recommendedBrotliSettings = true;
      recommendedOptimisation = true;
      recommendedTlsSettings = true;
      virtualHosts."navidrome.jonboh.dev" = {
        listen = [
          {
            addr = "0.0.0.0";
            port = 80;
            ssl = false;
          }
          {
            port = 443;
            addr = "0.0.0.0";
            ssl = true;
          }
        ];
        forceSSL = true;
        sslCertificate = "/var/lib/acme/jonboh.dev/fullchain.pem";
        sslCertificateKey = "/var/lib/acme/jonboh.dev/key.pem";
        locations."/" = {
          proxyPass = "http://${config.services.navidrome.settings.Address}:${toString config.services.navidrome.settings.Port}";
          recommendedProxySettings = true;
        };
      };
    };
    samba = {
      enable = true;
      nmbd.enable = false; # disable NETBIOS
      settings = {
        global = {
          "guest account" = "nobody";
          "smb ports" = "${toString sensitive.network.port.tcp.bragi.samba}";
          "hosts allow" = "${sensitive.network.vlan-range "lab"} ${sensitive.network.vlan-range "rift"} 127.0.0.1 localhost";
          "hosts deny" = "0.0.0.0/0";
        };
        media = {
          path = "/mnt/storage/shared_media";
          "read only" = true;
          browseable = true;
          public = true;
          comment = "Shared Media";
        };
        writable_media = {
          path = "/mnt/storage/shared_media";
          "read only" = false;
          writable = true;
          browseable = true;
          public = false;
          comment = "Writable Shared Media";
          "valid users" = "jonboh";
        };
        writable_music = {
          path = "/mnt/storage/music";
          "read only" = false;
          writable = true;
          browseable = true;
          public = false;
          comment = "Writable Music";
          "valid users" = "jonboh";
        };
        writable_music_exchange = {
          path = "/mnt/storage/music_exchange";
          "read only" = false;
          writable = true;
          browseable = true;
          public = false;
          comment = "Writable MusicExchange";
          "valid users" = "jonboh";
        };
      };
    };
  };
  system.activationScripts = {
    smbuser = ''
      cat /run/secrets/smb-password /run/secrets/smb-password | ${pkgs.samba}/bin/smbpasswd -a jonboh -s
    '';
  };

  fileSystems = {
    "/mnt/storage" = {
      device = "/dev/disk/by-label/media-drive";
      fsType = "ext4";
    };
  };

  environment.systemPackages = with pkgs; [
    bindfs
  ];

  system.stateVersion = "25.05";
}
