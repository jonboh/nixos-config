{
  pkgs,
  self,
  config,
  sensitive,
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
    package = pkgs.unstable.navidrome;
    settings = {
      Agents = "lastfm,deezer";
      MusicFolder = "/mnt/storage/music/main";
      DataFolder = "/mnt/storage/navidrome";
      CacheFolder = "/mnt/storage/navidrome/cache";
      Address = "127.0.0.1";
      Port = 4533;
      # Scanner.PurgeMissing = "full";
      BaseUrl = "https://navidrome.jonboh.dev";
      Backup = {
        Path = "/mnt/storage/navidrome-backup";
        Count = 7;
        Schedule = "0 0 * * *";
      };
    };
    environmentFile = config.sops.secrets.navidrome-env.path;
  };
  # NOTE: additional libraries need to be read by navidrome
  systemd.services.navidrome.serviceConfig.BindReadOnlyPaths = [
    "/mnt/storage/music/private"
    "/mnt/storage/music/hartaman"
  ];
  systemd.services.navidrome.serviceConfig.BindPaths = [
    "/mnt/storage/navidrome-backup"
  ];
  users.users.jonboh.extraGroups = ["navidrome"];

  environment.systemPackages = [pkgs.unstable.navidrome];
}
