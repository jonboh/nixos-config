{sensitive, ...}: {
  nix.buildMachines = [
    # NOTE: you can force the usage of the local machine by running:
    # nixos-rebuild <args> --builders ""
    {
      hostName = "localhost";
      protocol = null;
      systems = ["x86_64-linux"];
      maxJobs = 1;
      supportedFeatures = ["kvm" "nixos-test" "big-parallel" "benchmark"];
    }
    {
      hostName = "etna.lan";
      system = "aarch64-linux";
      protocol = "ssh";
      sshUser = "nixremote";
      sshKey = "/var/lib/hydra/.ssh/nixremote";
      maxJobs = 2;
      speedFactor = 2;
      supportedFeatures = ["kvm" "nixos-test" "big-parallel" "benchmark"];
    }
  ];
  nix.distributedBuilds = true;
  nix = {
    settings = {
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
