{self, ...}: {
  sops.age.keyFile = "/var/secrets/lab.txt";
  sops.secrets.smb-password = {
    format = "binary";
    sopsFile = self.inputs.nixos-config-sensitive + /secrets/smb-password;
  };
}
