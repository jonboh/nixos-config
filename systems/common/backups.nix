{config}: rec {
  basic-backup = {
    compression = "auto,zstd";
    encryption.mode = "none";
    doInit = false; # NOTE: doInit=false to prevent initializing  repos on places due to unmounted devices
    extraCreateArgs = ["--verbose" "--stats"];
    user = "root";
    persistentTimer = true;
    inhibitsSleep = true;
    environment = {
      BORG_RELOCATED_REPO_ACCESS_IS_OK = "yes";
      BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK = "yes";
    };
  };
  encrypted-backup =
    basic-backup
    // {
      encryption = {
        mode = "repokey";
        passCommand = "cat ${config.sops.secrets.borg-passhphrase.path}";
      };
    };
}
