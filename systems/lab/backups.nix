{
  self,
  config,
  sensitive,
  ...
}: {
  services.borgbackup.jobs = let
    b = import ../common/backups.nix {inherit config;};
    encrypted-backup = b.encrypted-backup;
    immich =
      encrypted-backup
      // {
        paths = ["/var/lib/immich"];
        preHook = ''
          sudo -u immich pg_dump --clean --if-exists --username=immich immich > /tmp/immich-database.sql && sudo chown immich:immich /tmp/immich-database.sql && sudo -u immich mv /tmp/immich-database.sql /var/lib/immich/backups/immich-database.sql
        '';
      };
  in {
    immich-remote =
      immich
      // {
        repo = "borgremote@thule.jonboh.dev:/mnt/storage/immich-borg";
        startAt = "Mon *-*-* 03:00:00";
      };
    # immich-lan =
    #   immich
    #   // {
    #     repo = "borgremote@lab.lan:/mnt/storage/immich-borg";
    #     startAt = "Mon *-*-* 01:00:00";
    #   };
  };

  sops.secrets.borg-passhphrase = {
    format = "binary";
    sopsFile = self.inputs.nixos-config-sensitive + /secrets/borg-backups-passphrase;
  };

  programs.ssh.knownHosts = {
    "thule.jonboh.dev" = {
      publicKey = sensitive.keys.ssh-host.thule;
    };
  };
}
