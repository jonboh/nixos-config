{pkgs, ...}: {
  home = {
    username = "jonboh";
    homeDirectory = "/home/jonboh";
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

  programs.password-store = {
    enable = true;
    package = pkgs.pass.withExtensions (exts: [exts.pass-otp]);
    settings = {
      PASSWORD_STORE_DIR = "/home/jonboh/.password-store";
    };
  };

  systemd.user.services.vault-update = {
    Unit = {
      Description = "Vault update";
    };
    Service = {
      # run vaultupdateall on startup
      ExecStart = "${pkgs.writeShellScript "vault-update" ''
        #!/run/current-system/sw/bin/bash
        /etc/profiles/per-user/jonboh/bin/git -C /home/jonboh/vault add . && \
        /etc/profiles/per-user/jonboh/bin/git -C /home/jonboh/vault commit -m 'update-all' && \
        /etc/profiles/per-user/jonboh/bin/git -C /home/jonboh/vault pull && \
        /etc/profiles/per-user/jonboh/bin/git -C /home/jonboh/vault push
      ''}";
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };
}
