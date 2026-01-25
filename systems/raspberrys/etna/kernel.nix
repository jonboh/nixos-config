{pkgs, ...}: let
  kernelBundle = pkgs.linuxAndFirmware.v6_6_74; # 6.12 breaks gpio on rp-fancontrol
in {
  boot = {
    loader.raspberry-pi.firmwarePackage = kernelBundle.raspberrypifw;
    loader.raspberry-pi.bootloader = "kernel";
    kernelPackages = kernelBundle.linuxPackages_rpi5;
  };
}
