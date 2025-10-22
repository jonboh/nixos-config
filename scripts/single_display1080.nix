{pkgs ? import <nixpkgs> {}}:
pkgs.writeShellScriptBin "single_display1080" ''
  xrandr --output DP-0 --off \
       --output DP-2 --primary --mode 1920x1080 --pos 0x0 --rotate normal
''
