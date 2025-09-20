{pkgs ? import <nixpkgs> {}}: let
  unfocus-network = pkgs.callPackage ./unfocus-network.nix {};
  restart-librewolf = pkgs.callPackage ./restart-librewolf.nix {};
in
  pkgs.writeShellScriptBin "unfocus-network" ''
    rg youtube /etc/hosts && (kitty --class="FloatingTermDialog" --title "Unfocus Network" sh -c "sudo ${pkgs.lib.getExe unfocus-network}" \
    && rg youtube /etc/hosts || ${pkgs.lib.getExe restart-librewolf})
  ''
