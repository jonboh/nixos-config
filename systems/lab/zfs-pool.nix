{sensitive, ...}: {
  boot.supportedFilesystems = ["zfs"];
  boot.zfs.forceImportRoot = false;
  networking.hostId = sensitive.ids.zfs.lab;
  # NOTE: mountpoint is managed by the pool
  # `sudo zfs set mountpoint=/mnt/storage datapool`
  boot.zfs.extraPools = ["datapool"]; # import the pool on boot so that it can be mounted on its mountpoint aka /mnt/storage
  services.zfs = {
    autoScrub = {
      enable = true;
      pools = ["datapool"];
    };
  };
}
