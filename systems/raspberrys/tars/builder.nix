{sensitive, ...}: {
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

      max-jobs = 2;
      cores = 1;
    };
  };

  systemd.services.nix-daemon.serviceConfig = {
    MemoryAccounting = true;
    MemoryHigh = "50%";
    MemoryMax = "75%";
    OOMScoreAdjust = 500; # see: https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html#OOMScoreAdjust=
  };

  nix.settings = {
    secret-key-files = ["/var/secrets/cache-priv-key.pem"];
  };
}
