{
  nix.buildMachines = [
    # NOTE: you can force the usage of the local machine by running:
    # nixos-rebuild <args> --builders ""
    # {
    #   hostName = "localhost";
    #   protocol = null;
    #   system = "x86_64-linux";
    #   supportedFeatures = ["kvm" "nixos-test" "big-parallel" "benchmark"];
    #   maxJobs = 8;
    # }
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
}
