{sensitive, ...}: {
  fileSystems."/" = {
    device = "/dev/mapper/crypted";
    fsType = "ext4";
  };

  # Needed to find the USB device during initrd stage
  boot.initrd.kernelModules = ["usb_storage"];

  boot.initrd.luks.devices."crypted" = {
    device = "/dev/disk/by-partlabel/nixospart";
    allowDiscards = true;
    keyFileSize = 4096;
    fallbackToPassword = true;
    # pinning to /dev/disk/by-id/usbkey works
    keyFile = "/dev/disk/by-id/${sensitive.hardware.id.lab-key}";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
    options = ["uid=0" "gid=0" "fmask=0077" "dmask=0077"];
  };
}
