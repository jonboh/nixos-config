{
  pkgs,
  lib,
  ...
}: {
  programs.zsh = {
    enable = true;
    syntaxHighlighting.enable = true;
    autosuggestion.enable = true;
    enableCompletion = true;
    #shellAliases = { }; # zsh specific aliases
    # initExtraFirst = ''
    #   zmodload zsh/zprof # then run zprof to profile zsh
    # '';
    initContent = let
      mainConfig = lib.mkOrder 1000 ''
        unsetopt BEEP

        export MANPAGER='nixvim-light +Man\! "+set relativenumber" -'

        autoload -Uz edit-command-line
        zle -N edit-command-line
        bindkey -M vicmd e edit-command-line

        source $XDG_CONFIG_HOME/zsh/.zshbindings

        # history
        HISTFILE="$HOME/.zsh_history"
        HISTSIZE=100000
        SAVEHIST=100000
        setopt EXTENDED_HISTORY          # Write the history file in the ":start:elapsed;command" format.
        setopt SHARE_HISTORY             # Share history between all sessions.
        setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history.
        setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again.
        setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
        setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space.
        setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
        setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.
        fancy-ctrl-z () {
          if [[ $#BUFFER -eq 0 ]]; then
            BUFFER=" fg"
            zle accept-line
          else
            zle push-input
            BUFFER=" fg"
            zle accept-line
          fi
        }
        zle -N fancy-ctrl-z
        bindkey '^Z' fancy-ctrl-z

        # yazi
        source $HOME/.flakes/nixos-config/extra_configs/yazi/yazi_wrapper.zsh
        bindkey -s '^b' 'y\n'

        # open editor
        bindkey -s '^e' 'e\n'

        fpath=($HOME/.flakes/nixos-config/extra_configs/zsh $fpath)
        fpath+=~/.config/zfunc_rustcompletions
        source $HOME/.flakes/nixos-config/extra_configs/zsh/cursor_mode.zsh
        _comp_options+=(globdots)
        source $HOME/.flakes/nixos-config/extra_configs/zsh/completion.zsh # Phantas0s completion options

        # initialize starship
        eval "$(starship init zsh)"

        # initialize direnv
        eval "$(direnv hook zsh)"

        mkz() {
            mkdir -p $1 && zoxide add $1 && cd $1
        }


        # shai intergration :D
        source $XDG_CONFIG_HOME/shai/zsh_assistant.zsh

      '';
      afterConfig = lib.mkOrder 1500 ''
        dsh() {
          nix develop "$HOME/.flakes/nixos-config#$1" --command zsh
        }

        gl1-specific() {
          git log --graph --color --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)' "$@";
        }
        gl2-specific() {
          git log --graph --color --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(auto)%d%C(reset)%n'''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)' "$@";
        }
        gl3-specific() {
          git log --graph --color --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset) %C(bold cyan)(committed: %cD)%C(reset) %C(auto)%d%C(reset)%n'''          %C(white)%s%C(reset)%n'''          %C(dim white)- %an <%ae> %C(reset) %C(dim white)(committer: %cn <%ce>)%C(reset)' "$@";
        }

        invert_gitgraph() {
          local cmd="$1"; shift
          echo "" | cat <("$cmd" "$@" 2>&1) - | tac | ${lib.getExe (pkgs.callPackage ../scripts/git_log_graph_invert_characters.nix {})} | less -FX +G
          # the echo and cat prevents tac from merging the first two lines in short stories
        }

        gl()   { invert_gitgraph gl1-specific "$@"; }
        gl2()  { invert_gitgraph gl2-specific "$@"; }
        gl3()  { invert_gitgraph gl3-specific "$@"; }
        gla()  { invert_gitgraph gl1-specific "$@" --all; }
        gla2() { invert_gitgraph gl2-specific "$@" --all; }
        gla3() { invert_gitgraph gl3-specific "$@" --all; }

        compdef _git gl=git-log
        compdef _git gl2=git-log
        compdef _git gl3=git-log
        compdef _git gla=git-log
        compdef _git gla2=git-log
        compdef _git gla3=git-log
      '';
    in
      lib.mkMerge [mainConfig afterConfig];
    plugins = [
      {
        name = "zsh-nix-shell";
        file = "nix-shell.plugin.zsh";
        src = pkgs.fetchFromGitHub {
          owner = "chisui";
          repo = "zsh-nix-shell";
          rev = "v0.7.0";
          sha256 = "149zh2rm59blr2q458a5irkfh82y3dwdich60s9670kl3cl5h2m1";
        };
      }
      {
        name = "fzf-tab";
        src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
      }
    ];
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    bashrcExtra = ''
      # initialize starship
      eval "$(starship init bash)"
    '';
  };

  # fzf
  programs.fzf.enable = true;
  # programs.fzf.fileWidgetCommand = "<file-search-command>"

  # zoxide
  programs.zoxide.enable = true;
}
