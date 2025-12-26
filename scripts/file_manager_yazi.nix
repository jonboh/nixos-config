{pkgs ? import <nixpkgs> {}}:
pkgs.writeShellScriptBin "file_manager_yazi" ''
  ${builtins.readFile ./file_manager_yazi.sh}
''
