{
  config,
  sensitive,
  ...
}: {
  users.users.nixremote = {
    isNormalUser = true;
    createHome = false;
    openssh.authorizedKeys.keys = [
      sensitive.keys.ssh.root-workstation
    ];
  };
  users.groups.nixremote = {};

  nix = {
    nrBuildUsers = 64;
    settings = {
      trusted-users = ["nixremote"];

      min-free = 32 * 1024 * 1024;
      max-free = 64 * 1024 * 1024;
    };
    optimise = {
      automatic = true;
      dates = ["03:45"];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
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
