{
  pkgs,
  self,
  config,
  sensitive,
  ...
}: {
  services.borgbackup.jobs = let
    b = import ../common/backups.nix {inherit config;};
    encrypted-backup = b.encrypted-backup;
    immich_path = "/mnt/storage/var/lib/immich";
    immich =
      encrypted-backup
      // {
        paths = [immich_path];
        readWritePaths = [immich_path "/tmp"];
        preHook = ''
          #!/usr/bin/bash
          ${pkgs.sudo}/bin/sudo -u immich ${config.services.postgresql.package}/bin/pg_dump --clean --if-exists --username=immich immich > /tmp/immich-database.sql && ${pkgs.sudo}/bin/sudo chown immich:immich /tmp/immich-database.sql && ${pkgs.sudo}/bin/sudo -u immich mv /tmp/immich-database.sql ${immich_path}/backups/immich-database.sql
        '';
      };
    archive =
      encrypted-backup
      // {
        paths = ["/mnt/storage/data/archive"];
      };
  in {
    immich-remote =
      immich
      // {
        repo = "borgremote@thule.jonboh.dev:/mnt/storage/backups/immich-borg";
        startAt = "Mon *-*-* 03:00:00";
      };
    immich-lan =
      immich
      // {
        repo = "borgremote@lab.lan:/mnt/storage/backups/immich-borg";
        startAt = "Mon *-*-* 01:00:00";
      };
    archive-remote =
      archive
      // {
        repo = "borgremote@thule.jonboh.dev:/mnt/storage/backups/archive-borg";
        startAt = "monthly";
      };
    archive-lan =
      archive
      // {
        repo = "borgremote@lab.lan:/mnt/storage/backups/archive-borg";
        startAt = "monthly";
      };
  };

  sops.secrets.borg-passhphrase = {
    format = "binary";
    sopsFile = self.inputs.nixos-config-sensitive + /secrets/borg-backups-passphrase;
  };

  programs.ssh.knownHosts = {
    "thule.jonboh.dev" = {
      publicKey = sensitive.keys.ssh-host.thule;
    };
    "lab.lan" = {
      publicKey = sensitive.keys.ssh-host.lab;
    };
  };
}
