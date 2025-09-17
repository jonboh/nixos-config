{pkgs ? import <nixpkgs> {}}: let
  unfocus-network = pkgs.callPackage ./unfocus-network.nix {};
  restart-librewolf = pkgs.callPackage ./restart-librewolf.nix {};
in
  pkgs.writeShellScriptBin "unfocus-network" ''
    kitty --class="FloatingTermDialog" --title "Unfocus Network" sh -c "sudo ${pkgs.lib.getExe unfocus-network}" \
    && ${pkgs.lib.getExe restart-librewolf}
  ''
