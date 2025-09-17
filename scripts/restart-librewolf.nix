{pkgs ? import <nixpkgs> {}}:
pkgs.writeShellScriptBin "restart-librewolf" ''
  if pgrep librewolf | grep -v restart-librewolf | grep -v focus-network > /dev/null; then
    pgrep librewolf | grep -v restart-librewolf | grep -v focus-network | xargs -r kill # dont kill yourself or your parent
    librewolf & disown
    sleep 0.5
  fi
  exit
''
