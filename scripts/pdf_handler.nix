{pkgs ? import <nixpkgs> {}}:
pkgs.writeScriptBin "pdf_handler" ''
  #!${pkgs.python3}/bin/python
  ${builtins.readFile ./pdf_handler.py}
''
