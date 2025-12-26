{pkgs, ...}: {
  hardware.opentabletdriver = {
    enable = true;
    package = pkgs.unstable.opentabletdriver;
  };
}
