{pkgs ? import <nixpkgs> {}}:
pkgs.writeShellScriptBin "killselect" ''
  kill -9 $(xprop | rg PID | awk '{print $3}')
''
