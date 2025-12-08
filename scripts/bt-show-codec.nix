{pkgs ? import <nixpkgs> {}}:
pkgs.writeScriptBin "bt-show-codec" ''
  ${builtins.readFile ./bt-show-codec.sh}
''
