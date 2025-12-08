{config, ...}: {
  nix = {
    optimise = {
      automatic = true;
      dates = ["03:45"];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 60d";
    };
  };

  programs.ccache = {
    enable = true;
    cacheDir = "/var/cache/ccache";
  };
  nix.settings.extra-sandbox-paths = [config.programs.ccache.cacheDir];

  nix.settings = {
    secret-key-files = ["/var/secrets/cache-priv-key.pem"];
  };

  systemd.services.nix-daemon.serviceConfig = {
    MemoryAccounting = true;
    MemoryHigh = "50%";
    MemoryMax = "75%";
    OOMScoreAdjust = 500; # see: https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html#OOMScoreAdjust=
  };
}
