{pkgs ? import <nixpkgs> {}}:
pkgs.writeShellScriptBin "zen-mode" ''
  ${pkgs.xorg.xwininfo}/bin/xwininfo -root -children |
      sed '1,/children:/d' |
      awk '{print $1}' |
      sed "/$(xprop -root _NET_ACTIVE_WINDOW | awk '{print $5}')/d" |
      while read id; do
          ${pkgs.picom}/bin/picom-trans -w $id -o 0 -t &
      done;
  wait;
  sleep 0.5;
  ${pkgs.picom}/bin/picom-trans -c -o 100;
''
