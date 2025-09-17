{
  nix.buildMachines = [
    # NOTE: you can force the usage of the local machine by running:
    # nixos-rebuild <args> --builders ""
    {
      hostName = "brick.lan";
      system = "aarch64-linux";
      protocol = "ssh-ng";
      maxJobs = 8;
      speedFactor = 2;
      supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];
      mandatoryFeatures = [];
    }
    {
      hostName = "tars.lan";
      system = "aarch64-linux";
      protocol = "ssh-ng";
      maxJobs = 1;
      speedFactor = 1;
      supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];
      mandatoryFeatures = [];
    }
    {
      hostName = "forge.lan";
      system = "aarch64-linux";
      protocol = "ssh-ng";
      maxJobs = 1;
      speedFactor = 1;
      supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];
      mandatoryFeatures = [];
    }
  ];
  nix.distributedBuilds = true;
  # these builder do not have internet, so use our own substituters
  nix.extraOptions = ''
    builders-use-substitutes = false
  '';
}
