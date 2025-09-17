{
  pkgs,
  config,
  ...
}: {
  fileSystems."/mnt/media_share" = {
    device = "//tars.lan/writable_media";
    fsType = "cifs";
    options = let
      automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=500ms,x-systemd.mount-timeout=500ms";
    in ["${automount_opts},credentials=/run/secrets-derived/smb-credentials,uid=1000,gid=100"];
  };
  fileSystems."/mnt/file_exchange" = {
    device = "//tars.lan/writable_file_exchange";
    fsType = "cifs";
    options = let
      automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=500ms,x-systemd.mount-timeout=500ms";
    in ["${automount_opts},credentials=/run/secrets-derived/smb-credentials,uid=1000,gid=100"];
  };

  systemd.services.smb-secrets = {
    description = "Create a credentials file for samba mountt to consume";
    wantedBy = ["multi-user.target"];
    path = [pkgs.coreutils];
    script = ''
      set -e
      token=$(cat ${config.sops.secrets.smb-password.path})
      if [ -d "/run/secrets-derived" ]; then
         rm -rf "/run/secrets-derived"
      fi
      mkdir -p /run/secrets-derived/
      echo "user=jonboh" > /run/secrets-derived/smb-credentials
      echo "password=$token" >> /run/secrets-derived/smb-credentials
      chmod 400 /run/secrets-derived/smb-credentials
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };
}
