{pkgs ? import <nixpkgs> {}}:
pkgs.writeShellScriptBin "ffnnn" ''
  ${builtins.readFile ./ffnnn.sh}
''
