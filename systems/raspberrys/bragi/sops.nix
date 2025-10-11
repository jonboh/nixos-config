{self, ...}: {
  sops.age.keyFile = "/var/secrets/bragi.txt";

  sops.secrets.smb-password = {
    format = "binary";
    sopsFile = self.inputs.nixos-config-sensitive + /secrets/smb-password;
  };

  sops.secrets.wg-bragi-private-key = {
    format = "binary";
    sopsFile = self.inputs.nixos-config-sensitive + /secrets/wg-bragi-private-key;
    mode = "640";
    owner = "systemd-network";
    group = "systemd-network";
  };
  sops.secrets.wg-bragi-psk = {
    format = "binary";
    sopsFile = self.inputs.nixos-config-sensitive + /secrets/wg-bragi-psk;
    mode = "640";
    owner = "systemd-network";
    group = "systemd-network";
  };

  sops.secrets.certs-secrets = {
    format = "binary";
    owner = "acme";
    group = "acme";
    sopsFile = self.inputs.nixos-config-sensitive + /secrets/dns-certs.secret;
  };
}
