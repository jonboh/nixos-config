{config, ...}: {
  xdg.configFile."OrcaSlicer" = {
    source =
      if config.home.symlink_flake
      then
        config.lib.file.mkOutOfStoreSymlink
        /home/jonboh/.flakes/system/extra_configs/OrcaSlicer
      else ../extra_configs/OrcaSlicer;
  };
}
