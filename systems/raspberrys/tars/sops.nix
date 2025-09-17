{self, ...}: {
  sops.age.keyFile = "/var/secrets/tars.txt";
  sops.secrets.smb-password = {
    format = "binary";
    sopsFile = self.inputs.nixos-config-sensitive + /secrets/smb-password;
  };
  sops.secrets.influxdb-password = {
    format = "binary";
    group = "influx-secrets";
    mode = "0440"; # Readable by the owner and group
    sopsFile = self.inputs.nixos-config-sensitive + /secrets/influxdb-password;
  };

  # MQTT
  sops.secrets.iaq-bedroom-mqtt-password = {
    format = "binary";
    sopsFile = self.inputs.nixos-config-sensitive + /secrets/iaq-bedroom-mqtt-password;
  };
  sops.secrets.iaq-outside-mqtt-password = {
    format = "binary";
    sopsFile = self.inputs.nixos-config-sensitive + /secrets/iaq-outside-mqtt-password;
  };
  sops.secrets.iaq-lab-mqtt-password = {
    format = "binary";
    sopsFile = self.inputs.nixos-config-sensitive + /secrets/iaq-lab-mqtt-password;
  };
  sops.secrets.influx-mqtt-password = {
    format = "binary";
    group = "influx-secrets";
    mode = "0440";
    sopsFile = self.inputs.nixos-config-sensitive + /secrets/influx-mqtt-password;
  };

  # Radicale
  sops.secrets.radicale-server-cert = {
    format = "binary";
    group = "radicale";
    mode = "0440";
    sopsFile = self.inputs.nixos-config-sensitive + /secrets/radicale-server-cert.pem;
  };
  sops.secrets.radicale-server-key = {
    format = "binary";
    group = "radicale";
    mode = "0440";
    sopsFile = self.inputs.nixos-config-sensitive + /secrets/radicale-server-key.pem;
  };
  sops.secrets.radicale-user = {
    format = "binary";
    group = "radicale";
    mode = "0440";
    sopsFile = self.inputs.nixos-config-sensitive + /secrets/radicale-user;
  };

  sops.secrets.tars-cert-key = {
    format = "binary";
    group = "nginx";
    mode = "0440";
    sopsFile = self.inputs.nixos-config-sensitive + /secrets/tars-selfsigned.key;
  };
}
