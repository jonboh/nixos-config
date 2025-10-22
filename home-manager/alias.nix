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
    "gla" = "gl1-specific --all | tac | ${lib.getExe (pkgs.callPackage ../scripts/git_log_graph_invert_characters.nix {})}| less -FX +G";
    "gla2" = "gl2-specific --all  | tac | ${lib.getExe (pkgs.callPackage ../scripts/git_log_graph_invert_characters.nix {})} | less -FX +G";
    "gla3" = "gl3-specific --all | tac | ${lib.getExe (pkgs.callPackage ../scripts/git_log_graph_invert_characters.nix {})} | less -FX +G";
    "gl" = "gl1-specific | tac | ${lib.getExe (pkgs.callPackage ../scripts/git_log_graph_invert_characters.nix {})} | less -FX +G";
    "gl2" = "gl2-specific | tac | ${lib.getExe (pkgs.callPackage ../scripts/git_log_graph_invert_characters.nix {})} | less -FX +G";
    "gl3" = "gl3-specific | tac | ${lib.getExe (pkgs.callPackage ../scripts/git_log_graph_invert_characters.nix {})} | less -FX +G";
    "gl1-specific" = "git log --graph --color --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)'";
    "gl2-specific" = "git log --graph --color --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(auto)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)'";
    "gl3-specific" = "git log --graph --color --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset) %C(bold cyan)(committed: %cD)%C(reset) %C(auto)%d%C(reset)%n''          %C(white)%s%C(reset)%n''          %C(dim white)- %an <%ae> %C(reset) %C(dim white)(committer: %cn <%ce>)%C(reset)'";

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
    "dragon" = "${pkgs.xdragon}/bin/xdragon --and-exit --all";
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
