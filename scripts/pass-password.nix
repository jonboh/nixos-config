{
  pkgs,
  keyname,
}:
pkgs.writeShellScriptBin "pass-password" ''
  is_vault_unlocked() {
      gpg-connect-agent 'keyinfo --list' /bye | rg $(gpg --fingerprint --with-keygrip ${keyname} | grep Keygrip | tail -n 1 | cut -d'=' -f2) | rg "D - - 1" > /dev/null
      return $?
  }
  if is_vault_unlocked; then
    pass $1 | head -1
  fi
''
