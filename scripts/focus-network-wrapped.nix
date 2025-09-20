{pkgs ? import <nixpkgs> {}}: let
  focus-network = pkgs.callPackage ./focus-network.nix {};
  restart-librewolf = pkgs.callPackage ./restart-librewolf.nix {};
in
  pkgs.writeShellScriptBin "focus-network" ''
    rg youtube /etc/hosts || (kitty --class="FloatingTermDialog" --title "Focus Network" sh -c "sudo ${pkgs.lib.getExe focus-network}" \
    && rg youtube /etc/hosts && ${pkgs.lib.getExe restart-librewolf})
  ''
