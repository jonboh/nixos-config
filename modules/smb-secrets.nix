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

  config = lib.mkIf config.secrets.smbPassword.enable {
    sops.secrets.smb-password = {
      format = "binary";
      sopsFile = self.inputs.nixos-config-sensitive + /secrets/smb-password;
    };
  };
}
