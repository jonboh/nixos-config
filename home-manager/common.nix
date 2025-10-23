{
  self,
  pkgs,
  config,
  lib,
  ...
}: {
  imports = [
    ./direnv.nix
    ./shell.nix
    ./alias.nix
    ./dunst.nix
    ./udiskie.nix
    ./unclutter.nix
    ./xresources.nix
    ./yazi.nix
  ];
  programs.home-manager.enable = true;

  services.ssh-agent.enable = true;

  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    flags = ["--disable-up-arrow" "--disable-ctrl-r"]; # fuzzy search is not good enough, use atuin just for syncing
    settings = {
      auto_sync = true;
      sync_frequency = "5m";
      sync_address = "https://atuin.jonboh.dev";
      prefers_reduced_motion = true;
      style = "compact";
      search_mode = "skim";
      workspaces = true;
      enter_accept = false;
      inline_height = 20;
    };
  };

  xdg.configFile."zsh" = {
    enable = true;
    source =
      if config.home.symlink_flake
      then
        config.lib.file.mkOutOfStoreSymlink
        /home/jonboh/.flakes/nixos-config/extra_configs/zsh
      else ../extra_configs/zsh;
  };
  xdg.configFile."kitty" = {
    enable = true;
    source =
      if config.home.symlink_flake
      then
        config.lib.file.mkOutOfStoreSymlink
        /home/jonboh/.flakes/nixos-config/extra_configs/kitty
      else ../extra_configs/kitty;
  };
  xdg.configFile."kitty-scrollback-loading" = {
    enable = true;
    source = ../extra_configs/kitty/loading.py;
    target = "python/loading.py";
  };
  xdg.configFile."newsboat" = {
    enable = true;
    source =
      if config.home.symlink_flake
      then
        config.lib.file.mkOutOfStoreSymlink
        /home/jonboh/.flakes/nixos-config-extra-private/newsboat
      else self.inputs.nixos-config-extra-private + /newsboat;
  };
  xdg.configFile."zfunc_rustcompletions" = {
    enable = true;
    source =
      if config.home.symlink_flake
      then
        config.lib.file.mkOutOfStoreSymlink
        /home/jonboh/.flakes/nixos-config/extra_configs/zfunc_rustcompletions
      else ../extra_configs/zfunc_rustcompletions;
  };
  xdg.configFile."xdg-desktop-portal-termfilechooser" = {
    enable = true;
    source = ../extra_configs/xdg-desktop-portal-termfilechooser;
  };
  xdg.configFile."rofi" = {
    enable = true;
    source = ../extra_configs/rofi;
  };
  xdg.configFile."bacon" = {
    enable = true;
    source =
      if config.home.symlink_flake
      then config.lib.file.mkOutOfStoreSymlink /home/jonboh/.flakes/nixos-config/extra_configs/bacon
      else ../extra_configs/bacon;
  };
  xdg.configFile."shai" = {
    enable = true;
    source = ../extra_configs/shai;
  };
  xdg.configFile."zathura" = {
    enable = true;
    source =
      if config.home.symlink_flake
      then config.lib.file.mkOutOfStoreSymlink /home/jonboh/.flakes/nixos-config/extra_configs/zathura
      else ../extra_configs/zathura;
  };
  xdg.configFile."OpenSCAD" = {
    enable = true;
    source = config.lib.file.mkOutOfStoreSymlink /home/jonboh/.flakes/nixos-config/extra_configs/OpenSCAD;
  };
  xdg.configFile."starship.toml" = {
    source =
      if config.home.symlink_flake
      then
        config.lib.file.mkOutOfStoreSymlink
        /home/jonboh/.flakes/nixos-config/extra_configs/starship/starship.toml
      else ../extra_configs/starship/starship.toml;
  };
  xdg.configFile."rofi-pass" = {
    source =
      if config.home.symlink_flake
      then
        config.lib.file.mkOutOfStoreSymlink
        /home/jonboh/.flakes/nixos-config/extra_configs/rofi-pass
      else ../extra_configs/rofi-pass;
  };
  xdg.configFile."allmytoes" = {
    source =
      if config.home.symlink_flake
      then
        config.lib.file.mkOutOfStoreSymlink
        /home/jonboh/.flakes/nixos-config/extra_configs/allmytoes
      else ../extra_configs/allmytoes;
  };
  home.file.".julia/config/" = {
    enable = true;
    source = config.lib.file.mkOutOfStoreSymlink /home/jonboh/.flakes/nixos-config/extra_configs/julia_config;
  };
  home.file.".local/share/applications/" = {
    enable = true;
    source = config.lib.file.mkOutOfStoreSymlink /home/jonboh/.flakes/nixos-config/extra_configs/desktop_entries;
  };

  programs.git = {
    enable = true;
    delta.enable = true;
    userName = "jonboh";
    userEmail = "jon.bosque.hernando@gmail.com";
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      rerere.enabled = true;
      safe.directory = "/nix/store/*"; # NOTE: ugly shit to fix ESP-IDF flake build
      alias = {
        clone-worktree = "!sh ${pkgs.callPackage ../scripts/git-clone-for-worktrees.nix {}}/bin/git-clone-for-worktrees";
      };
    };
  };

  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/interface" = {color-scheme = "prefer-dark";};
    };
  };

  gtk = let
    tokyonight-package = pkgs.tokyonight-gtk-theme.overrideAttrs (oldAttrs: {
      src = pkgs.fetchFromGitHub {
        owner = "Fausto-Korpsvart";
        repo = "Tokyonight-GTK-Theme";
        rev = "0a03005a02b9eba130e158cd1169d542e3a5a99a";
        hash = "sha256-WRFFjYLwZM42zgGsGmVdUmaFrLlYibgBsFvhgG5VHNU=";
      };
    });
  in {
    enable = true;
    # theme = {
    #   name = "Tokyonight-Dark";
    #   package = tokyonight-package;
    # };
    # iconTheme = {
    #   name = "Tokyonight-Dark";
    #   package = tokyonight-package;
    # };
    theme = {
      name = "Adwaita-dark";
    };
    iconTheme = {
      name = "Adwaita-dark";
    };
    cursorTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
  };

  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";
    extraConfig = ''
      Host *
          ServerAliveInterval 10
          ServerAliveCountMax 3
    '';
    includes = ["~/.ssh/hosts"];
  };

  services.picom = {
    enable = true;
    activeOpacity = 1.0;
    inactiveOpacity = 0.75;
    opacityRules = ["100:class_g = 'Rofi'" "100:class_g = 'xlock'" "100:class_g = 'i3lock'"];
  };
}
