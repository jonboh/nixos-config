{
  pkgs,
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

      max-jobs = "auto";
      cores = 0;
    };
  };

  systemd.services.nix-daemon.serviceConfig = {
    MemoryAccounting = true;
    MemoryHigh = "85%";
    MemoryMax = "95%";
    OOMScoreAdjust = 500;
  };

  nix.settings = {
    secret-key-files = ["/var/secrets/cache-priv-key.pem"];
  };

  programs.ccache = {
    enable = true;
    cacheDir = "/var/cache/ccache";
  };
  nix.settings.extra-sandbox-paths = [config.programs.ccache.cacheDir];
}
