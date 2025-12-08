{
  imports = [../common/builder.nix];
  nix = {
    nrBuildUsers = 64;
    settings = {
      max-jobs = 2;
      cores = 1;
    };
  };
}
