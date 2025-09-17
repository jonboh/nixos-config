{pkgs, ...}: let
  open_vault_package = pkgs.callPackage ../packages/anki-open-vaul.nix {};
in {
  home.file.".local/share/Anki2/addons21/open_vault" = {
    source = "${open_vault_package}";
  };
}
