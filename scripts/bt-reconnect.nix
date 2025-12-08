{pkgs ? import <nixpkgs> {}}:
pkgs.writeScriptBin "bt-reconnect" ''
  ${builtins.readFile ./bt-reconnect.sh}
''
