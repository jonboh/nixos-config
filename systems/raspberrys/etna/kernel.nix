{pkgs, ...}: let
  kernelBundle = pkgs.linuxAndFirmware.latest;
in {
  boot = {
    loader.raspberry-pi.firmwarePackage = kernelBundle.raspberrypifw;
    loader.raspberry-pi.bootloader = "kernel";
    kernelPackages = kernelBundle.linuxPackages_rpi5;
  };
}
