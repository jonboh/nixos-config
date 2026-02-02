{
  self,
  config,
  lib,
  ...
}: {
  options.secrets.smbPassword.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable smb-password secret from sops.";
  };
  options.secrets.smbGaladrielPassword.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable smb-password for galadriel secret from sops.";
  };

  config.sops.secrets.smb-password = lib.mkIf config.secrets.smbPassword.enable {
    format = "binary";
    sopsFile = self.inputs.nixos-config-sensitive + /secrets/smb-password;
  };

  config.sops.secrets.smb-galadriel-password = lib.mkIf config.secrets.smbGaladrielPassword.enable {
    format = "binary";
    sopsFile = self.inputs.nixos-config-sensitive + /secrets/smb-galadriel-password;
  };
}
