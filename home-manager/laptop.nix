{
  imports = [./common.nix ./gui-apps.nix ./i3.nix];
  home.symlink_flake = true;
  home.computer = "laptop";
}
