{pkgs ? import <nixpkgs> {}}:
pkgs.writeShellScriptBin "screenshot" ''
  FILE=$(date +$HOME/screenshots/%Y-%m-%d-%H_%M_%S.png)
  mkdir -p $HOME/screenshots && scrot $FILE && xclip -selection clipboard -t image/png -i $FILE && krita --nosplash --canvasonly --workspace Vault $FILE
''
