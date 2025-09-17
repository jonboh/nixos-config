{
  pkgs,
  keyname,
}:
pkgs.writeShellScriptBin "rofi-password-store" ''
  is_vault_unlocked() {
      gpg-connect-agent 'keyinfo --list' /bye | rg $(gpg --fingerprint --with-keygrip ${keyname} | grep Keygrip | tail -n 1 | cut -d'=' -f2) | rg "D - - 1"
      return $?
  }

  WINDOW_TITLE="Password"
  ${pkgs.wmctrl}/bin/wmctrl -F -c "$WINDOW_TITLE"
  if [ $? -ne 0 ]; then
    if ! is_vault_unlocked; then
        # Vault is locked, spawn a Kitty window to unlock it
        kitty --class="FloatingTermDialog" --title "Unlock password-store" sh -c 'pass show unlock' &
        kitty_pid=$!
        # Wait for the Kitty window to close
        wait $kitty_pid
        if ! is_vault_unlocked; then
            echo "Unlock operation was aborted. Exiting."
            exit 1
        fi
    fi
    ${pkgs.rofi-pass}/bin/rofi-pass
    # PASSWORD=$(
    #   rofi-rbw \
    #     --clear-after 15 \
    #     --action print \
    #     --target "username" \
    #     --keybindings "Alt+p:type:password,Alt+P:print:password,Alt+c:copy:password,Alt+u:copy:username,Alt+s:sync"
    #   )
    # [[ -n $PASSWORD ]] && ${pkgs.zenity}/bin/zenity \
    #     --warning \
    #     --no-wrap \
    #     --text="<span font=\"FiraCode 20\" foreground=\"red\">$PASSWORD</span>" \
    #     --title=$WINDOW_TITLE
  fi
''
