{
  nix.buildMachines = [
    # NOTE: you can force the usage of the local machine by running:
    # nixos-rebuild <args> --builders ""
    {
      hostName = "etna.lan";
      system = "aarch64-linux";
      protocol = "ssh-ng";
      sshUser = "nixremote";
      sshKey = "/root/.ssh/nixremote";
      maxJobs = 1;
      speedFactor = 2;
      supportedFeatures = ["kvm" "nixos-test" "big-parallel" "benchmark"];
    }
  ];
  nix.distributedBuilds = true;
}
