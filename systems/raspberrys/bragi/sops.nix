{self, ...}: {
  sops.age.keyFile = "/var/secrets/bragi.txt";

  secrets.smbPassword.enable = true;

  sops.secrets.certs-secrets = {
    format = "binary";
    owner = "acme";
    group = "acme";
    sopsFile = self.inputs.nixos-config-sensitive + /secrets/dns-certs.secret;
  };
}
