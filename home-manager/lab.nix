{
  imports = [
    ./options.nix
    ./common.nix
    ./jonboh-user.nix
    ./gui-apps.nix
    ./i3.nix
  ];
  home.symlink_flake = true;
  home.computer = "lab";
}
