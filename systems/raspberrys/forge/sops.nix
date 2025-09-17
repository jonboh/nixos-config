{self, ...}: {
  sops.age.keyFile = "/var/secrets/forge.txt";
  sops.secrets.forge-cert-key = {
    format = "binary";
    group = "nginx";
    mode = "0440";
    sopsFile = self.inputs.nixos-config-sensitive + /secrets/forge-selfsigned.key;
  };
}
