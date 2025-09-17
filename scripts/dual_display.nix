{pkgs ? import <nixpkgs> {}}:
pkgs.writeShellScriptBin "dual_display" ''
  xrandr --output DP-0 --mode 2560x1440 --pos 0x0 --rotate normal \
       --output DP-2 --primary --mode 2560x1440 --pos 2560x0 --rotate normal
''
