{
  imports = [../common/builder.nix];
  nix = {
    settings = {
      max-jobs = 2;
      cores = 1;
    };
  };
}
