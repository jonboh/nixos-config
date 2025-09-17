{...}: {
  services.borgbackup.jobs = {
    devel-daily = {
      paths = ["/mnt/storage/devel"];
      encryption.mode = "none";
      repo = "/mnt/storage/daily-backup/devel";
      compression = "auto,zstd";
      startAt = "daily"; # will start at 00:00:00, see systemd.time(7)
      exclude = [
        "*/target"
        "*/build"
        "*/dist"
        "*/out"
        "*/.eggs"
        "*/node_modules"
        "*/.pytest_cache"
        "*/.tox"
        "*/.venv"
        "*.tmp"
      ];
      environment.BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK = "yes";
      extraCreateArgs = ["--verbose" "--stats"];
      user = "jonboh";
    };
    git-daily = {
      paths = ["/mnt/storage/git-server"];
      encryption.mode = "none";
      repo = "/mnt/storage/daily-backup/git-server";
      compression = "auto,zstd";
      startAt = "daily"; # will start at 00:00:00, see systemd.time(7)
      environment.BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK = "yes";
      extraCreateArgs = ["--verbose" "--stats"];
      user = "git";
    };
  };
  # TODO: add activation script for daily-backup, such that it is writtable by group users
  # needed for git to be able to backup on fresh installs
  # NOTE: repos need to be initialized with
  # ```bash
  # export BACKUP_NAME=git-server
  # export BORG_REPO=/mnt/storage/daily-backup/$BACKUP_NAME
  # borg init -e none $BORG_REPO
  # borg config $BORG_REPO additional_free_space 4G
  # ```
}
