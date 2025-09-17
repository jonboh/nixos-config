{pkgs ? import <nixpkgs> {}}:
pkgs.writeScriptBin "git-init-tars" ''
  #!${pkgs.python3}/bin/python
  ${builtins.readFile ./git-init-tars.py}
''
