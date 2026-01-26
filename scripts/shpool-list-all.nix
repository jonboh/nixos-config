{pkgs ? import <nixpkgs> {}}:
pkgs.writeShellScriptBin "shpool-list-all" ''
  ${builtins.readFile ./shpool-list-all.sh}
''
