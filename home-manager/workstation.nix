{config, ...}: {
  imports = [
    ./options.nix
    ./common.nix
    ./jonboh-user.nix
    ./gui-apps.nix
    ./i3.nix
  ];
  # link locations from storage
  home.file."vault" = {
    enable = true;
    source = config.lib.file.mkOutOfStoreSymlink /mnt/storage/vault;
    target = "vault";
  };
  home.file."doc" = {
    enable = true;
    source = config.lib.file.mkOutOfStoreSymlink /mnt/storage/doc;
    target = "doc";
  };
  home.file."devel" = {
    enable = true;
    source = config.lib.file.mkOutOfStoreSymlink /mnt/storage/devel;
    target = "devel";
  };
  home.file."books" = {
    enable = true;
    source = config.lib.file.mkOutOfStoreSymlink /mnt/storage/books;
    target = "books";
  };
  xdg.configFile."starship.toml" = {
    source =
      if config.home.symlink_flake
      then
        config.lib.file.mkOutOfStoreSymlink
        /home/jonboh/.flakes/nixos-config/extra_configs/starship/starship.toml
      else ../extra_configs/starship/starship.toml;
  };
  home.symlink_flake = true;
  home.computer = "workstation";
  home.mutable_okular = true;
  home.mutable_krita = false;
}
