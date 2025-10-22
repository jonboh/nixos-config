{pkgs}:
pkgs.writeShellScriptBin "is_vault_unlocked" ''
  is_vault_unlocked() {
      keyname="$1"
      gpg-connect-agent 'keyinfo --list' /bye | rg $(gpg --fingerprint --with-keygrip "$keyname" | grep Keygrip | tail -n 1 | cut -d'=' -f2) | rg "D - - 1"
      return $?
  }

  is_vault_unlocked "$@"
''
