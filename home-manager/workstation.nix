{config, ...}: {
  imports = [./common.nix ./gui-apps.nix ./i3.nix];
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
  home.symlink_flake = true;
  home.computer = "workstation";
  home.mutable_okular = true;
  home.mutable_krita = false;
}
