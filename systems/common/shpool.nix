{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    shpool
  ];

  # Enable systemd user services to persist after logout
  services.logind.killUserProcesses = false;

  # Configure systemd user service for shpool. See https://github.com/shell-pool/shpool/tree/master/systemd
  systemd.user.services.shpool = {
    description = "Shpool - Shell Session Pool";
    requires = ["shpool.socket"];
    after = ["shpool.socket"];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.shpool}/bin/shpool daemon";
      KillMode = "mixed";
      TimeoutStopSec = "2s";
      SendSIGHUP = "yes";
      Restart = "on-failure";
      RestartSec = "1s";
    };

    wantedBy = ["default.target"];
  };

  # Configure systemd user socket for shpool
  systemd.user.sockets.shpool = {
    description = "Shpool Shell Session Pooler";

    socketConfig = {
      ListenStream = "%t/shpool/shpool.socket";
      SocketMode = "0600";
      DirectoryMode = "0700";
    };

    wantedBy = ["sockets.target"];
  };

  # Enable lingering for users so systemd user services persist after logout
  # This ensures shpool daemon stays running even when no SSH sessions are active
  users.users.jonboh.linger = true;

  # Configure bash to set huponexit for better process cleanup
  # This ensures background processes exit when leaving a shell session
  programs.bash.interactiveShellInit = ''
    # Set huponexit for better process cleanup in shpool sessions
    if [[ -n "$SHPOOL_SESSION_NAME" ]]; then
        shopt -s huponexit
    fi
  '';

  environment.etc = {
    "shpool.toml" = {
      source = pkgs.writeText "shpool.toml" ''
        prompt_prefix = ""
      '';
      user = "jonboh";
      group = "users";
    };
  };

  system.activationScripts = {
    shpool-config = ''
      if ! [ -e /home/jonboh/.config/shpool/config.toml ]; then
         mkdir -p /home/jonboh/.config/shpool
         ln -s /etc/shpool.toml /home/jonboh/.config/shpool/config.toml
      fi
    '';
  };

  programs.starship = {
    enable = true;
    settings = builtins.fromTOML (builtins.readFile ../../extra_configs/starship/starship-server.toml);
  };

  environment.shellAliases = {
    sp = "shpool attach";
    spl = "shpool list";
    spd = "shpool detach";
    spk = "shpool kill";
  };

  # Ensure XDG_RUNTIME_DIR is properly set for all users
  # This is needed for the socket path
  environment.sessionVariables = {
    XDG_RUNTIME_DIR = "/run/user/$UID";
  };
}
