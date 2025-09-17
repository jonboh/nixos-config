{self, ...}: {
  sops.secrets.influxdb-token = {
    format = "binary";
    group = "influx-secrets";
    mode = "0440"; # Readable by the owner and group
    sopsFile = self.inputs.nixos-config-sensitive + /secrets/influxdb-token;
  };
  users.groups.influx-secrets = {};
}
