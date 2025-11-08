{self, ...}: {
  sops.age.keyFile = "/var/secrets/charon.txt";

  sops.secrets.wifiPasswordCharon = {
    format = "binary";
    sopsFile = self.inputs.nixos-config-sensitive + /secrets/wifiPasswordCharon;
  };
  sops.secrets.wifiPasswordRift = {
    format = "binary";
    sopsFile = self.inputs.nixos-config-sensitive + /secrets/wifiPasswordRift;
  };
  sops.secrets.wifiPasswordWarp = {
    format = "binary";
    sopsFile = self.inputs.nixos-config-sensitive + /secrets/wifiPasswordWarp;
  };
}
