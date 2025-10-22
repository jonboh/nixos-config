{
  config,
  pkgs,
  lib,
  ...
}: let
  kernelBundle = pkgs.linuxAndFirmware.v6_12_44;
in {
  boot = {
    loader.raspberryPi.firmwarePackage = kernelBundle.raspberrypifw;
    loader.raspberryPi.bootloader = "kernel";
    kernelPackages = kernelBundle.linuxPackages_rpi5;
  };
}
