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
      sensitive.keys.ssh.workstation
    ];
  };
  users.groups.nixremote = {};

  # Kernel memory management for better build performance under constraints
  boot.kernel.sysctl = {
    # Memory overcommit settings for better swap usage
    "vm.overcommit_memory" = 1; # Always overcommit (needed for builds that estimate high memory usage)
    "vm.overcommit_ratio" = 150; # Allow overcommitting 150% of RAM + swap

    # Swap behavior - be more aggressive about swapping when memory is constrained
    "vm.swappiness" = 30; # Default is 60, good balance for build workloads
    "vm.vfs_cache_pressure" = 50; # Retain dentries and inodes in cache under memory pressure

    # Memory management
    "vm.dirty_background_ratio" = 5; # Start writing dirty pages early
    "vm.dirty_ratio" = 15; # Maximum dirty pages before blocking writes
  };

  nix = {
    nrBuildUsers = 64;
    settings = {
      trusted-users = ["nixremote"];

      # Resource management for builds
      max-jobs = 1; # Only allow 1 concurrent build to respect memory limits
      # cores = 2; # Use maximum 2 cores per build

      # Additional build settings to reduce resource usage
      # build-cores = 2; # Explicitly set build cores
      # max-silent-time = 36000; # 10 hour timeout for silent builds
      # timeout = 72000; # 20 hour total timeout for builds
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
}
