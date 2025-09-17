{pkgs ? import <nixpkgs> {}}: let
  focus-network = pkgs.callPackage ./focus-network.nix {};
  restart-librewolf = pkgs.callPackage ./restart-librewolf.nix {};
in
  pkgs.writeShellScriptBin "focus-network" ''
    kitty --class="FloatingTermDialog" --title "Unfocus Network" sh -c "sudo ${pkgs.lib.getExe focus-network}" \
    && ${pkgs.lib.getExe restart-librewolf}
  ''
