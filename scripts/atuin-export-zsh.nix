{pkgs ? import <nixpkgs> {}}:
pkgs.writeScriptBin "atuin-export-zsh" ''
  #!${pkgs.python3}/bin/python
  ${builtins.readFile ./atuin-export-zsh.py}
''
