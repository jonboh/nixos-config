{config, ...}: {
  xdg.configFile."OrcaSlicer" = {
    source =
      if config.home.symlink_flake
      then
        config.lib.file.mkOutOfStoreSymlink
        /home/jonboh/.flakes/nixos-config-extra-private/OrcaSlicer
      else ../extra_configs/OrcaSlicer;
  };
}
