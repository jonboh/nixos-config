{pkgs ? import <nixpkgs> {}}: let
  dual_display = pkgs.callPackage ./dual_display.nix {};
  turn_tablet_on = pkgs.callPackage ./turn_tablet_on.nix {};
  turn_tablet_off = pkgs.callPackage ./turn_tablet_off.nix {};
in
  pkgs.writeShellScriptBin "dual_display_and_tablet" ''
    ${pkgs.lib.getExe dual_display}
    if xrandr --query | grep -oP 'HDMI-0 connected .+ \(' > /dev/null; then
       ${pkgs.lib.getExe turn_tablet_on}
    else
      ${pkgs.lib.getExe turn_tablet_off}
    fi
  ''
