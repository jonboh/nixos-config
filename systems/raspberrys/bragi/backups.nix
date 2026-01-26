{
  self,
  config,
  sensitive,
  ...
}: {
  services.borgbackup.jobs = let
    b = import ../../common/backups.nix {inherit config;};
    encrypted-backup = b.encrypted-backup;
    basic-backup = b.basic-backup;
    navidrome =
      encrypted-backup
      // {
        paths = ["/mnt/storage/navidrome-backup"];
      };
    music =
      basic-backup
      // {
        paths = ["/mnt/storage/music"];
      };
  in {
    navidrome-remote =
      navidrome
      // {
        repo = "borgremote@thule.jonboh.dev:/mnt/storage/backups/navidrome-borg";
        startAt = "Fri *-*-* 01:00:00";
      };
    navidrome-lan =
      navidrome
      // {
        repo = "borgremote@lab.lan:/mnt/storage/backups/navidrome-borg";
        startAt = "Fri *-*-* 01:05:00";
      };
    music-remote =
      music
      // {
        repo = "borgremote@thule.jonboh.dev:/mnt/storage/backups/music-borg";
        startAt = "Fri *-*-* 01:10:00";
      };
    music-lan =
      music
      // {
        repo = "borgremote@lab.lan:/mnt/storage/backups/music-borg";
        startAt = "Fri *-*-* 02:10:00";
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
