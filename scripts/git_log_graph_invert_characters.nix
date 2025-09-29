{pkgs ? import <nixpkgs> {}}:
pkgs.writeScriptBin "git_log_graph_invert_characters" ''
  #!${pkgs.python3}/bin/python
  ${builtins.readFile ./git_log_graph_invert_characters.py}
''
