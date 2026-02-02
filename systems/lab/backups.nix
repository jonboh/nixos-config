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
    doc =
      encrypted-backup
      // {
        paths = ["/mnt/storage/data/doc"];
      };
    galadriel =
      encrypted-backup
      // {
        paths = ["/mnt/storage/data/galadriel"];
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
        startAt = "Thu *-*-* 01:00:00";
      };
    archive-remote =
      archive
      // {
        repo = "borgremote@thule.jonboh.dev:/mnt/storage/backups/archive-borg";
        startAt = "*-*-01 00:00:00";
      };
    archive-lan =
      archive
      // {
        repo = "borgremote@lab.lan:/mnt/storage/backups/archive-borg";
        startAt = "*-*-15 00:00:00";
      };
    doc-remote =
      doc
      // {
        repo = "borgremote@thule.jonboh.dev:/mnt/storage/backups/doc-borg";
        startAt = "Tue *-*-* 01:00:00";
      };
    doc-lan =
      doc
      // {
        repo = "borgremote@lab.lan:/mnt/storage/backups/doc-borg";
        startAt = "Fri *-*-* 01:00:00";
      };
    galadriel-remote =
      galadriel
      // {
        repo = "borgremote@thule.jonboh.dev:/mnt/storage/backups/galadriel-borg";
        startAt = "Wed *-*-* 01:00:00";
      };
    galadriel-lan =
      galadriel
      // {
        repo = "borgremote@lab.lan:/mnt/storage/backups/galadriel-borg";
        startAt = "Sat *-*-* 01:00:00";
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
