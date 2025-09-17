{
  pkgs,
  config,
  ...
}: {
  programs.nnn = {
    enable = true;
    package = pkgs.nnn.override {withNerdIcons = true;};
    extraPackages = with pkgs; [
      mediainfo
      trash-cli
      poppler_utils # for pdftoppm, pdf thumbnail
      sshfs
      nsxiv
      viu
      xdragon
      ffmpegthumbnailer
      (pkgs.writeScriptBin
        "cpg"
        ''
          ${pkgs.uutils-coreutils}/bin/uutils-cp --progress --interactive "$@"
        '')
      (pkgs.writeScriptBin
        "mvg"
        ''
          ${pkgs.uutils-coreutils}/bin/uutils-mv --progress --interactive "$@"
        '')
    ];
  };

  xdg.configFile."nnn/plugins" = {
    enable = true;
    source =
      if config.home.symlink_flake
      then
        config.lib.file.mkOutOfStoreSymlink
        /home/jonboh/.flakes/system/extra_configs/nnn/plugins
      else ../extra_configs/nnn/plugins;
  };
}
