{self, ...}: {
  sops.age.keyFile = "/var/secrets/lab.txt";
  sops.secrets.smb-password = {
    format = "binary";
    sopsFile = self.inputs.nixos-config-sensitive + /secrets/smb-password;
  };

  sops.secrets.wg-lab-private-key = {
    format = "binary";
    sopsFile = self.inputs.nixos-config-sensitive + /secrets/wg-lab-private-key;
    mode = "640";
    owner = "systemd-network";
    group = "systemd-network";
  };
  sops.secrets.wg-lab-psk = {
    format = "binary";
    sopsFile = self.inputs.nixos-config-sensitive + /secrets/wg-lab-psk;
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

  sops.secrets.influxdb-token = {
    format = "binary";
    group = "influx-secrets";
    mode = "0440"; # Readable by the owner and group
    sopsFile = self.inputs.nixos-config-sensitive + /secrets/influxdb-token;
  };
  users.groups.influx-secrets = {};
}
