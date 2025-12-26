{pkgs, ...}: {
  systemd.timers = {
    # "move-it" = {
    #   wantedBy = ["timers.target"];
    #   timerConfig = {
    #     OnBootSec = "180m";
    #     OnUnitActiveSec = "180m";
    #     Unit = "move-it.service";
    #   };
    # };
    "anki" = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "150m";
        OnUnitActiveSec = "300m";
        Unit = "anki.service";
      };
    };

    update-tldr = {
      description = "Weekly TLDR pages update timer";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "weekly"; # Schedule the timer to run weekly
        Persistent = true;
      };
    };
  };

  systemd.services = {
    # "move-it" = {
    #   script = ''
    #     export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$UID/bus"
    #     ${pkgs.libnotify}/bin/notify-send "Time to move it" -t 1000000000
    #   '';
    #   serviceConfig = {
    #     Type = "oneshot";
    #     # Environment = "DISPLAY=:0";
    #     User = "jonboh";
    #   };
    # };

    "anki" = {
      script = ''
        export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$UID/bus"
        /run/current-system/sw/bin/notify-send "ANKI" -t 1000000000
      '';
      serviceConfig = {
        Type = "oneshot";
        # Environment = "DISPLAY=:0";
        User = "jonboh";
      };
    };

    focus-network = let
      focus-network-pkg = pkgs.callPackage ../../../../scripts/focus-network.nix {};
    in {
      description = "Network focus by default";
      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];
      script = ''${focus-network-pkg}/bin/focus-network'';
    };

    # Create a systemd service for updating the tldr database
    update-tldr = {
      description = "Weekly TLDR pages update";
      serviceConfig = {
        Type = "oneshot"; # Important for a timer-triggered service
        User = "jonboh";
        After = ["network-online.target"]; # Wait for the network to be online
        WantedBy = ["multi-user.target"]; # This should ensure the service gets started correctly
        Restart = "on-failure"; # Restart the service on failure
        RestartSec = 5; # Wait 5 seconds before restarting the service
      };
      script = "${pkgs.tldr}/bin/tldr --update"; # Update TLDR pages
    };
  };
}
