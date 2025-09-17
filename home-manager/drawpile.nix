{
  self,
  config,
  lib,
  ...
}: {
  options.home.mutable_drawpile = lib.mkOption {
    type = lib.types.bool;
    default = false;
  };
  config = {
    xdg.configFile."drawpile" = {
      enable = true;
      source =
        if config.home.mutable_drawpile
        then
          config.lib.file.mkOutOfStoreSymlink
          /home/jonboh/.flakes/nixos-configs-private/drawile
        else self.inputs.nixos-config-extra-private + /drawpile;
    };
  };
}
