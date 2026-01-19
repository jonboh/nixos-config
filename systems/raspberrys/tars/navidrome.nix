{
  pkgs,
  self,
  config,
  ...
}: {
  sops.secrets.navidrome-env = {
    format = "dotenv";
    sopsFile = self.inputs.nixos-config-sensitive + /secrets/navidrome.env;
    owner = config.services.navidrome.user;
    group = config.services.navidrome.group;
  };

  services.navidrome = {
    enable = true;
    package = pkgs.navidrome;
    settings = {
      Agents = "lastfm,deezer";
      MusicFolder = "/mnt/media-drive/music/main";
      DataFolder = "/mnt/media-drive/navidrome";
      CacheFolder = "/mnt/media-drive/navidrome/cache";
      Address = "127.0.0.1";
      Port = 4533;
      # Scanner.PurgeMissing = "full";
      BaseUrl = "https://navidrome.jonboh.dev";
      Backup = {
        Path = "/mnt/media-drive/navidrome-backup";
        Count = 7;
        Schedule = "0 0 * * *";
      };
    };
    environmentFile = config.sops.secrets.navidrome-env.path;
  };
  users.users.nginx.extraGroups = ["acme"];
  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
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
  # NOTE: additional libraries need to be read by navidrome
  systemd.services.navidrome.serviceConfig.BindReadOnlyPaths = [
    "/mnt/media-drive/music/private"
    "/mnt/media-drive/music/hartaman"
  ];
  systemd.services.navidrome.serviceConfig.BindPaths = [
    "/mnt/media-drive/navidrome-backup"
  ];
  users.users.jonboh.extraGroups = ["navidrome"];

  fileSystems = {
    "/mnt/media-drive" = {
      device = "/dev/disk/by-label/media-drive";
      fsType = "ext4";
    };
  };

  environment.systemPackages = [pkgs.navidrome];
}
