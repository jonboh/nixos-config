{pkgs ? import <nipkgs> {}}:
pkgs.writeShellScriptBin "git-clone-for-worktrees" ''
  ${builtins.readFile ./git-clone-for-worktrees.sh}
''
