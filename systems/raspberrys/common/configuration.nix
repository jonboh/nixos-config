{
  pkgs,
  lib,
  sensitive,
  ...
}: let
  user = "jonboh";
in {
  time.timeZone = "Europe/Madrid";

  users = {
    mutableUsers = false;
    users."${user}" = {
      isNormalUser = true;
      hashedPassword = sensitive.passwords.jonboh-raspberries;
      extraGroups = ["wheel"];
      openssh.authorizedKeys.keys = [
        sensitive.keys.ssh.workstation
      ];
      uid = 1000;
    };
  };
  security.sudo.wheelNeedsPassword = false;

  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      require-sigs = true;
      trusted-public-keys = [
        sensitive.keys.nix.workstation
        sensitive.keys.nix.brick
        sensitive.keys.nix.tars
        sensitive.keys.nix.forge
        sensitive.keys.nix.hydra-lab
      ];
    };
  };

  hardware.enableRedistributableFirmware = true;

  configure.ntpd-rs.enable = true;
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

    vector = {
      enable = true;
      journaldAccess = true;
      settings = {
        sources = {
          journald.type = "journald";
          vector_metrics.type = "internal_metrics";
        };
        sinks = {
          loki = {
            type = "loki";
            inputs = ["journald"];
            endpoint = "https://loki.jonboh.dev";
            encoding = {codec = "json";};
            labels.source = "journald";
          };
        };
      };
    };
  };

  systemd.services.ntpd-rs.serviceConfig = lib.mkDefault {
    Restart = "on-failure";
    RestartSec = "5min";
  };

  environment.systemPackages = with pkgs; [
    libraspberrypi
    file
    git
    vim
    htop
    dust
    ntp
  ]; # NOTE: vcgencmd needs sudo to run

  boot.initrd.postDeviceCommands = ''
    info "Repairing all filesystems"
    fsck -A -y -V
  '';

  systemd.sleep.extraConfig = ''
    AllowSuspend=no
    AllowHibernation=no
    AllowHybridSleep=no
    AllowSuspendThenHibernate=no
  '';
}
