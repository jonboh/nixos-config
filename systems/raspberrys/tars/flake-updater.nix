{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.flakeUpdater;
in
  with lib; {
    options.flakeUpdater = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the flake updater systemd services.";
      };

      repos = mkOption {
        type = with types;
          listOf (submodule {
            options = {
              repoName = mkOption {
                type = types.str;
                description = "Name of the git repository (used in systemd service name)";
              };

              repoUrl = mkOption {
                type = types.str;
                description = "Git URL of the repository to update";
              };

              branch = mkOption {
                type = types.str;
                default = "main";
                description = "Main branch to base flake-update on";
              };

              user = mkOption {
                type = types.str;
                default = "git";
                description = "User to run the updater as";
              };

              frequency = mkOption {
                type = types.str;
                default = "daily";
                description = ''
                  Frequency to run the updater as a systemd timer.
                  Examples: "daily", "*-*-* 02:00:00" (for custom OnCalendar values).
                '';
              };
            };
          });
        default = [];
        description = "List of repositories to run flake updater for.";
      };
    };

    config.systemd = mkIf cfg.enable (
      let
        services =
          map (
            repo: let
              repoName = repo.repoName;
              repoUrl = repo.repoUrl;
              branch = repo.branch;
              user = repo.user;
              frequency = repo.frequency;
              timerOnCalendar =
                if frequency == "daily"
                then "daily"
                else frequency;
            in {
              services."update-flake-${repoName}" = {
                description = "Update the ${repoName} flake";
                after = ["network-online.target"];
                wants = ["network-online.target"];
                path = [pkgs.coreutils pkgs.git pkgs.openssh pkgs.nix];
                serviceConfig = {
                  Type = "oneshot";
                  ExecStart = ''
                    ${pkgs.runtimeShell} ${pkgs.writeText "flake-updater.sh" ''
                      set -euo pipefail
                      TMPDIR=$(mktemp -d)
                      cd "$TMPDIR"
                      git clone ${repoUrl} source
                      cd source

                      git checkout origin/${branch}

                      # Create or reset flake-update branch to main
                      git checkout -B flake-update ${branch}

                      nix flake update

                      git add flake.lock
                      git commit -m "Update flake.lock" || true
                      git push origin flake-update --force

                      cd /tmp
                      rm -rf "$TMPDIR"
                    ''}
                  '';
                  PrivateTmp = true;
                  NoNewPrivileges = true;
                  User = user;
                };
                wantedBy = ["multi-user.target"];
              };

              timers."update-flake-${repoName}" = {
                description = "Timer for update-flake-${repoName}";
                wantedBy = ["timers.target"];
                timerConfig = {
                  OnCalendar = timerOnCalendar;
                  Persistent = true;
                  Unit = "update-flake-${repoName}";
                };
              };
            }
          )
          cfg.repos;
        mergedServices = foldl (a: b: lib.recursiveUpdate a b) {} services;
      in
        mergedServices
    );
  }
