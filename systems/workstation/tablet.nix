{pkgs, ...}: {
  hardware.opentabletdriver = {
    enable = true;
    package = pkgs.opentabletdriver;
  };
}
