{
  self,
  pkgs,
  config,
  lib,
  ...
}: {
  options.home.mutable_krita = lib.mkOption {
    type = lib.types.bool;
    default = false;
  };
  options.home.krita-tencolors-dev = lib.mkOption {
    type = lib.types.bool;
    default = false;
  };
  options.home.krita-vault-integration-dev = lib.mkOption {
    type = lib.types.bool;
    default = false;
  };
  config = {
    xdg.configFile."kritarc" = {
      enable = true;
      source =
        if config.home.mutable_krita
        then
          config.lib.file.mkOutOfStoreSymlink
          /home/jonboh/.flakes/nixos-config-extra-private/krita/config/kritarc
        else self.inputs.nixos-config-extra-private + /krita/config/kritarc;
    };
    xdg.configFile."kritashortcutsrc" = {
      enable = true;
      source =
        if config.home.mutable_krita
        then
          config.lib.file.mkOutOfStoreSymlink
          /home/jonboh/.flakes/nixos-config-extra-private/krita/config/kritashortcutsrc
        else self.inputs.nixos-config-extra-private + /krita/config/kritashortcutsrc;
    };
    home.file.".local/share/krita/workspaces" = {
      enable = true;
      source =
        if config.home.mutable_krita
        then
          config.lib.file.mkOutOfStoreSymlink
          /home/jonboh/.flakes/nixos-config-extra-private/krita/share/workspaces
        else self.inputs.nixos-config-extra-private + /krita/share/workspaces;
    };
    home.file.".local/share/krita/paintoppresets" = {
      enable = true;
      source =
        if config.home.mutable_krita
        then
          config.lib.file.mkOutOfStoreSymlink
          /home/jonboh/.flakes/nixos-config-extra-private/krita/share/paintoppresets
        else self.inputs.nixos-config-extra-private + /krita/share/paintoppresets;
    };
    home.file.".local/share/krita/palettes" = {
      enable = true;
      source =
        if config.home.mutable_krita
        then
          config.lib.file.mkOutOfStoreSymlink
          /home/jonboh/.flakes/nixos-config-extra-private/krita/share/palettes
        else self.inputs.nixos-config-extra-private + /krita/share/palettes;
    };
    home.file.".local/share/krita/templates" = {
      enable = true;
      source =
        if config.home.mutable_krita
        then
          config.lib.file.mkOutOfStoreSymlink
          /home/jonboh/.flakes/nixos-config-extra-private/krita/share/templates
        else self.inputs.nixos-config-extra-private + /krita/share/templates;
    };
    home.file.".local/share/krita/brushes" = {
      enable = true;
      source =
        if config.home.mutable_krita
        then
          config.lib.file.mkOutOfStoreSymlink
          /home/jonboh/.flakes/nixos-config-extra-private/krita/share/brushes
        else self.inputs.nixos-config-extra-private + /krita/share/brushes;
    };

    home.file.".local/share/krita/actions/tencolors.action" = {
      enable = true;
      source =
        if config.home.krita-tencolors-dev
        then
          config.lib.file.mkOutOfStoreSymlink
          /home/jonboh/devel/tencolors/tencolors.action
        else "${pkgs.callPackage ../packages/krita-tencolors.nix {}}/tencolors.action";
    };
    home.file.".local/share/krita/pykrita/tencolors" = {
      enable = true;
      source =
        if config.home.krita-tencolors-dev
        then
          config.lib.file.mkOutOfStoreSymlink
          /home/jonboh/devel/tencolors
        else pkgs.callPackage ../packages/krita-tencolors.nix {};
    };
    home.file.".local/share/krita/pykrita/tencolors.desktop" = {
      enable = true;
      source =
        if config.home.krita-tencolors-dev
        then
          config.lib.file.mkOutOfStoreSymlink
          /home/jonboh/devel/tencolors
        else "${pkgs.callPackage ../packages/krita-tencolors.nix {}}/tencolors.desktop";
    };
    home.file.".local/share/krita/pykrita/krita_vault_integration" = {
      enable = true;
      source =
        if config.home.krita-vault-integration-dev
        then
          config.lib.file.mkOutOfStoreSymlink
          /home/jonboh/devel/krita_vault_integration
        else pkgs.callPackage ../packages/krita-vault-integration.nix {};
    };
    home.file.".local/share/krita/pykrita/krita_vault_integration.desktop" = {
      enable = true;
      source =
        if config.home.krita-vault-integration-dev
        then
          config.lib.file.mkOutOfStoreSymlink
          /home/jonboh/devel/krita_vault_integration/krita_vault_integration.desktop
        else "${pkgs.callPackage ../packages/krita-vault-integration.nix {}}/krita_vault_integration.desktop";
    };

    xdg.configFile."OpenTabletDriver" = {
      enable = true;
      source = config.lib.file.mkOutOfStoreSymlink /home/jonboh/.flakes/nixos-config/extra_configs/OpenTabletDriver;
      # NOTE: opentabletdriver.service crashes when linked to the inmutable configuration
    };
  };
}
