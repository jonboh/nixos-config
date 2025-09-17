{pkgs ? import <nixpkgs> {}}:
pkgs.writeShellScriptBin "single_display" ''
  xrandr --output DP-0 --off \
       --output DP-2 --primary --mode 2560x1440 --pos 0x0 --rotate normal
''
