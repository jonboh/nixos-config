{
  imports = [
    ./options.nix
    ./common.nix
    ./jonboh-user.nix
  ];
  home.symlink_flake = true;
  home.computer = "wsl";
}
