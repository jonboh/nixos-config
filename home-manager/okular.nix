{
  self,
  config,
  lib,
  ...
}: {
  options.home.mutable_okular = lib.mkOption {
    type = lib.types.bool;
    default = false;
  };
  config = {
    xdg.configFile."okularrc" = {
      enable = true;
      source =
        if config.home.mutable_okular
        then
          config.lib.file.mkOutOfStoreSymlink
          /home/jonboh/.flakes/nixos-configs-private/okular/config/okularrc
        else self.inputs.nixos-config-extra-private + /okular/config/okularrc;
    };
    xdg.configFile."okularpartrc" = {
      enable = true;
      source =
        if config.home.mutable_okular
        then
          config.lib.file.mkOutOfStoreSymlink
          /home/jonboh/.flakes/nixos-configs-private/okular/config/okularpartrc
        else self.inputs.nixos-config-extra-private + /okular/config/okularpartrc;
    };
    home.file.".local/share/kxmlgui5" = {
      enable = true;
      source =
        if config.home.mutable_okular
        then
          config.lib.file.mkOutOfStoreSymlink
          /home/jonboh/.flakes/nixos-configs-private/okular/share/kxmlgui5
        else self.inputs.nixos-config-extra-private + /okular/share/kxmlgui5;
    };
  };
}
