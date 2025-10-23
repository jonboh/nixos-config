{
  home = {
    username = "hermes";
    homeDirectory = "/home/hermes";
    stateVersion = "22.05";
    sessionVariables = {
      XDG_CACHE_HOME = "$HOME/.cache";
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_STATE_HOME = "$HOME/.local/state";
      XDG_BIN_HOME = "$HOME/.local/bin"; # Not officially in the specification
      GTK_USE_PORTAL = 1; # makes librewolf use ffnnn (based on yazi now)
      VISUAL = "nixvim-light";
      EDITOR = "nixvim-light";
      TERM = "kitty";
    };
    sessionPath = [
      "$XDG_BIN_HOME"
    ];
  };
}
