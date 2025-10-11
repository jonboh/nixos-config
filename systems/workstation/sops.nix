{self, ...}: {
  sops.age.keyFile = "/home/jonboh/.config/sops/age/keys.txt";
  sops.secrets.smb-password = {
    format = "binary";
    sopsFile = self.inputs.nixos-config-sensitive + /secrets/smb-password;
  };

  sops.secrets.wg-workstation-private-key = {
    format = "binary";
    sopsFile = self.inputs.nixos-config-sensitive + /secrets/wg-workstation-private-key;
    mode = "640";
    owner = "systemd-network";
    group = "systemd-network";
  };
  sops.secrets.wg-workstation-psk = {
    format = "binary";
    sopsFile = self.inputs.nixos-config-sensitive + /secrets/wg-workstation-psk;
    mode = "640";
    owner = "systemd-network";
    group = "systemd-network";
  };
}
