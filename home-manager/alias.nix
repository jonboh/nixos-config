{
  pkgs,
  lib,
  ...
}: let
  config = pkgs.neovimUtils.makeNeovimConfig {
    extraLuaPackages = p: [p.magick];
    extraPackages = p: [p.imagemagick];
    # ... other config
  };
  neovim-custom =
    pkgs.wrapNeovimUnstable
    (pkgs.neovim-unwrapped.overrideAttrs (oldAttrs: {
      buildInputs = oldAttrs.buildInputs ++ [pkgs.tree-sitter];
    }))
    config;
in {
  home.shellAliases = {
    # dotfiles
    "vault" = "git -C ~/vault";
    "vaultupdateall" = "vault add . && vault commit -m 'update-all' && vault pull && vault push";

    "cp" = "${pkgs.uutils-coreutils}/bin/uutils-cp --progress --interactive";
    "mv" = "${pkgs.uutils-coreutils}/bin/uutils-mv --progress --no-clobber --interactive";
    "cpg" = "cp";
    "mvg" = "mv";

    # git
    "gs" = "git status -s";
    "gsl" = "git status";
    "ga" = "git add";
    "gc" = "git commit";
    "gd" = "git diff";
    "gw" = "git worktree";
    "gr" = "git reset";
    "gf" = "git fetch";
    "gfa" = "git fetch --all";

    # modern utilities
    "diff" = "batdiff --delta";
    "cat" = "${pkgs.bat}/bin/bat";
    "man" = "${pkgs.bat-extras.batman}/bin/batman";
    "ls" = "${pkgs.eza}/bin/exa --color=always -1 --group-directories-first";
    "l" = "${pkgs.eza}/bin/exa --color=always --icons -F -1 --group-directories-first";
    "la" = "${pkgs.eza}/bin/exa --color=always --icons -F -1 --group-directories-first -a";
    "ll" = "${pkgs.eza}/bin/exa --color=always --icons -F -1 --group-directories-first -l -a -g";
    "fd" = "${pkgs.fd}/bin/fd --hidden";

    # Trash
    "rt" = "${pkgs.trash-cli}/bin/trash-put";
    "rm" = ''echo "prefer rt to trash things, run \\\rm if you really want to rm something."'';

    # kitty kittens
    "ssh" = "kitten ssh";
    "icat" = "kitten icat";

    # other
    "dragon" = "${pkgs.dragon-drop}/bin/xdragon --and-exit --all";
    "drag" = "dragon";
    "clip" = "xclip -sel clipboard";
    "lsblk" = "lsblk -o NAME,RM,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINT";

    # xdg-open
    "o" = "xdg-open";

    # editor
    "e" = "${pkgs.nixvim}/bin/nixvim";
    "nvim" = "${neovim-custom}/bin/nvim -u $HOME/.config/nvim/init.lua";

    "j" = "julia";
  };
}
