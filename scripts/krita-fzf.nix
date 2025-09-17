{pkgs ? import <nixpkgs> {}}:
pkgs.writeShellScriptBin "krita-fzf" ''
  ${pkgs.coreutils}/bin/ls -t $(find /home/jonboh/vault/files -type f -name '*.kra') | fzf --preview '${./krita-fzf-preview.sh} {}' | xargs -o -I {} sh -c "krita --nosplash \"{}\" > /dev/null 2>&1 & disown"
''
