{
  imports = [./common.nix ./i3.nix];
  home.symlink_flake = true;
  home.computer = "laptop";
}
