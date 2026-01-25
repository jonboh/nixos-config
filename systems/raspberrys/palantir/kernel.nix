{
  config,
  pkgs,
  lib,
  ...
}: let
  kernelBundle = pkgs.linuxAndFirmware.v6_12_44;
in {
  boot = {
    loader.raspberry-pi.firmwarePackage = kernelBundle.raspberrypifw;
    loader.raspberry-pi.bootloader = "kernel";
    kernelPackages = kernelBundle.linuxPackages_rpi5;
  };
}
