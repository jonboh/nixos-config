{...}: {
  fileSystems."/" = {
    device = "/dev/mapper/crypted";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."crypted".device = "/dev/disk/by-partlabel/nixospart";

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
    options = ["uid=0" "gid=0" "fmask=0077" "dmask=0077"];
  };

  swapDevices = [
    {
      device = "/dev/disk/by-partlabel/nixosswap";
      randomEncryption.enable = true;
    }
  ];

}
