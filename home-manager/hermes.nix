{
  imports = [
    ./options.nix
    ./common.nix
    ./hermes-user.nix
    ./librewolf.nix
    ./i3.nix
  ];
  home.computer = "hermes";
  home.symlink_flake = false;
}
