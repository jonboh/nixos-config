{
  self,
  pkgs,
  config,
  sensitive,
  ...
}: {
  services.borgbackup.jobs = let
    b = import ../../common/backups.nix {inherit config;};
    encrypted-backup = b.encrypted-backup;
    radicale =
      encrypted-backup
      // {
        paths = ["/mnt/storage/radicale"];
      };
    atuin =
      encrypted-backup
      // {
        paths = ["/mnt/storage/backups/atuin"];
        readWritePaths = ["/mnt/storage/backups"];
        preHook = ''
          mkdir -p /mnt/storage/backups/atuin
          ${pkgs.sudo}/bin/sudo -u postgres ${config.services.postgresql.package}/bin/pg_dump atuin > /mnt/storage/backups/atuin/atuin_backup.sql
        '';
      };
    firefox-syncserver =
      encrypted-backup
      // {
        paths = ["/mnt/storage/backups/firefox-syncserver"];
        readWritePaths = ["/mnt/storage/backups"];
        preHook = ''
          mkdir -p /mnt/storage/backups/firefox-syncserver
          ${pkgs.sudo}/bin/sudo -u firefox-syncserver ${config.services.mysql.package}/bin/mysqldump -u firefox-syncserver --all-databases > /mnt/storage/backups/firefox-syncserver/firefox_syncserver_databases.sql
        '';
      };

    vault =
      encrypted-backup
      // {
        paths = ["/mnt/storage/vault"];
      };
    books =
      encrypted-backup
      // {
        paths = ["/mnt/storage/books"];
      };
  in {
    radicale-remote =
      radicale
      // {
        repo = "borgremote@thule.jonboh.dev:/mnt/storage/backups/radicale-borg";
        startAt = "Sun *-*-* 03:00:00";
      };
    radicale-lan =
      radicale
      // {
        repo = "borgremote@lab.lan:/mnt/storage/backups/radicale-borg";
        startAt = "Sun *-*-* 03:02:00";
      };
    firefox-syncserver-remote =
      firefox-syncserver
      // {
        repo = "borgremote@thule.jonboh.dev:/mnt/storage/backups/firefox-syncserver-borg";
        startAt = "Sun *-*-* 03:05:00";
      };
    firefox-syncserver-lan =
      firefox-syncserver
      // {
        repo = "borgremote@lab.lan:/mnt/storage/backups/firefox-syncserver-borg";
        startAt = "Sun *-*-* 03:07:00";
      };
    atuin-remote =
      atuin
      // {
        repo = "borgremote@thule.jonboh.dev:/mnt/storage/backups/atuin-borg";
        startAt = "Sun *-*-* 03:10:00";
      };
    atuin-lan =
      atuin
      // {
        repo = "borgremote@lab.lan:/mnt/storage/backups/atuin-borg";
        startAt = "Sun *-*-* 03:12:00";
      };
    vault-remote =
      vault
      // {
        repo = "borgremote@thule.jonboh.dev:/mnt/storage/backups/vault-borg";
        startAt = "Sun *-*-* 03:15:00";
      };
    vault-lan =
      vault
      // {
        repo = "borgremote@lab.lan:/mnt/storage/backups/vault-borg";
        startAt = "Sun *-*-* 03:20:00";
      };
    books-remote =
      books
      // {
        repo = "borgremote@thule.jonboh.dev:/mnt/storage/backups/books-borg";
        startAt = "Sun *-*-* 03:25:00";
      };
    books-lan =
      books
      // {
        repo = "borgremote@lab.lan:/mnt/storage/backups/books-borg";
        startAt = "Sun *-*-* 03:30:00";
      };
  };

  sops.secrets.borg-passhphrase = {
    format = "binary";
    sopsFile = self.inputs.nixos-config-sensitive + /secrets/borg-backups-passphrase;
  };

  programs.ssh.knownHosts = {
    "lab.lan" = {
      publicKey = sensitive.keys.ssh-host.lab;
    };
    "thule.jonboh.dev" = {
      publicKey = sensitive.keys.ssh-host.thule;
    };
  };
}
