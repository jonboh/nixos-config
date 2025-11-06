{sensitive, ...}: {
  fileSystems."/" = {
    device = "/dev/vg0/root";
    fsType = "ext4";
  };

  # Needed to find the USB device during initrd stage
  boot.initrd.kernelModules = ["usb_storage"];

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
    options = ["uid=0" "gid=0" "fmask=0077" "dmask=0077"];
  };
}
