{sensitive, ...}: {
  nix.buildMachines = [
    # NOTE: you can force the usage of the local machine by running:
    # nixos-rebuild <args> --builders ""
    {
      hostName = "localhost";
      protocol = null;
      system = "x86_64-linux";
      supportedFeatures = ["kvm" "nixos-test" "big-parallel" "benchmark"];
      maxJobs = 2;
    }
    {
      hostName = "localhost";
      protocol = null;
      system = "aarch64-linux";
      maxJobs = 2;
      supportedFeatures = ["kvm" "nixos-test" "big-parallel" "benchmark"];
    }
    {
      hostName = "tars.lan";
      system = "aarch64-linux";
      protocol = "ssh";
      sshUser = "nixremote";
      sshKey = "/var/lib/hydra/.ssh/nixremote";
      maxJobs = 1;
      speedFactor = 1;
      supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];
      mandatoryFeatures = [];
    }
    {
      hostName = "forge.lan";
      system = "aarch64-linux";
      protocol = "ssh";
      sshUser = "nixremote";
      sshKey = "/var/lib/hydra/.ssh/nixremote";
      maxJobs = 1;
      speedFactor = 1;
      supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];
      mandatoryFeatures = [];
    }
  ];
  nix.distributedBuilds = true;
  nix = {
    settings = {
      # min-free = 32 * 1024 * 1024;
      # max-free = 64 * 1024 * 1024;

      max-jobs = 2;
      cores = 1;
    };
  };

  users.users.nixremote = {
    isNormalUser = true;
    createHome = false;
    openssh.authorizedKeys.keys = [
      sensitive.keys.ssh.root-workstation
    ];
  };
  users.groups.nixremote = {};
}
