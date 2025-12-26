{
  pkgs,
  sensitive,
  ...
}: {
  imports = [
    ./base.nix
  ];

  boot.initrd.checkJournalingFS = false; # manually done on PostDeviceCommand
  boot.initrd.enable = true;
  boot.initrd.postDeviceCommands = ''
    info "Repairing all filesystems"
    fsck -A -y -V
  '';

  users = {
    mutableUsers = false;
    users.jonboh = {
      openssh.authorizedKeys.keys = [
        sensitive.keys.ssh.workstation
      ];
    };
  };
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    dust
  ];

  services = {
    openssh = {
      enable = true;
      allowSFTP = true;
      openFirewall = true;
      settings = {
        LogLevel = "VERBOSE";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = pkgs.lib.mkForce "no";
        ClientAliveInterval = 10;
        ClientAliveCountMax = 3;

        KexAlgorithms = [
          "sntrup761x25519-sha512@openssh.com"
          "curve25519-sha256"
          "curve25519-sha256@libssh.org"
          "ecdh-sha2-nistp256"
          "ecdh-sha2-nistp384"
          "ecdh-sha2-nistp521"
          "diffie-hellman-group-exchange-sha256"
          "diffie-hellman-group16-sha512"
          "diffie-hellman-group18-sha512"
          "diffie-hellman-group14-sha256"
        ];
      };
    };
    fail2ban = {
      enable = true;
      maxretry = 10;
      bantime-increment.enable = true;
    };
  };
}
