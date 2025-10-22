{
  pkgs ? import <nixpkgs> {},
  keyname,
}:
pkgs.writeShellScriptBin "rofi-password-store" ''
  WINDOW_TITLE="Password"
  ${pkgs.wmctrl}/bin/wmctrl -F -c "$WINDOW_TITLE"
  if [ $? -ne 0 ]; then
    if ! is_vault_unlocked; then
        # Vault is locked, spawn a Kitty window to unlock it
        kitty --class="FloatingTermDialog" --title "Unlock password-store" sh -c 'pass show unlock' &
        kitty_pid=$!
        # Wait for the Kitty window to close
        wait $kitty_pid
        if ! ${pkgs.callPackage ./is_vault_unlocked.nix {}}/bin/is_vault_unlocked ${keyname}; then
            echo "Unlock operation was aborted. Exiting."
            exit 1
        fi
    fi
    ${pkgs.rofi-pass}/bin/rofi-pass
  fi
''
