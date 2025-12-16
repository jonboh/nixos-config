{
  config,
  pkgs,
  lib,
  ...
}: let
  kernelBundle = pkgs.linuxAndFirmware.v6_6_74; # 6.12 breaks gpio on rp-fancontrol
in {
  boot = {
    loader.raspberryPi.firmwarePackage = kernelBundle.raspberrypifw;
    loader.raspberryPi.bootloader = "kernel";
    kernelPackages = kernelBundle.linuxPackages_rpi5;
  };
}
