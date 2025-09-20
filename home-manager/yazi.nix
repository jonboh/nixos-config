{pkgs, ...}: {
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    plugins = {
      git = pkgs.yaziPlugins.git;
      toggle-pane = pkgs.yaziPlugins.toggle-pane;
      smart-enter = pkgs.yaziPlugins.smart-enter;
      lsar = pkgs.yaziPlugins.lsar;
      # also allmytoes
    };
    initLua = ../extra_configs/yazi/init.lua;
    settings = builtins.fromTOML (builtins.readFile ../extra_configs/yazi/yazi.toml);
    keymap = builtins.fromTOML (builtins.readFile ../extra_configs/yazi/keymap.toml);
    theme = builtins.fromTOML (builtins.readFile ../extra_configs/yazi/theme.toml);
    # use https://github.com/aguirre-matteo/nix-yazi-flavors?tab=readme-ov-file
  };

  # Not packaged on nixpkgs
  xdg.configFile."yazi/plugins/allmytoes.yazi" = {
    source = ../extra_configs/yazi/plugins/allmytoes.yazi;
  };
  xdg.configFile."yazi/flavors/tokyo-night.yazi" = {
    source = ../extra_configs/yazi/flavors/tokyo-night.yazi;
  };
}
