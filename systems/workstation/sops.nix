{self, ...}: {
  sops.age.keyFile = "/home/jonboh/.config/sops/age/keys.txt";
  sops.secrets.smb-password = {
    format = "binary";
    sopsFile = self.inputs.nixos-config-sensitive + /secrets/smb-password;
  };
}
