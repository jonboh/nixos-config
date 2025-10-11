{self, ...}: {
  sops.age.keyFile = "/var/secrets/forge.txt";
  sops.secrets.certs-secrets = {
    format = "binary";
    owner = "acme";
    group = "acme";
    sopsFile = self.inputs.nixos-config-sensitive + /secrets/dns-certs.secret;
  };
}
