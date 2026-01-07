{
  self,
  config,
  ...
}: {
  sops.age.keyFile = "/var/secrets/brick.txt";

  sops.secrets.charon_password = {
    format = "binary";
    sopsFile = self.inputs.nixos-config-sensitive + /secrets/wifiPasswordCharon;
  };
  sops.templates.charon_psk.content = ''
    psk_charon=${config.sops.placeholder.charon_password}
  '';
}
