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
      ];
    };
  };

  hardware.enableRedistributableFirmware = true;

  services = {
    ntpd-rs = {
      enable = true;
      settings = {
        source = [
          {
            address = sensitive.network.ntp-server "lab";
            mode = "server";
          }
        ];
        synchronization = {
          minimum-agreeing-sources = 1;
          single-step-panic-threshold = 1000;
          startup-step-panic-threshold = {
            forward = "inf";
            backward = 86400;
          };
        };
      };
      useNetworkingTimeServers = false;
    };

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
          "curve25519-sha256@libssh.org"
          "ecdh-sha2-nistp521"
          "ecdh-sha2-nistp384"
          "ecdh-sha2-nistp256"
          "diffie-hellman-group-exchange-sha256"
        ];
        Ciphers = [
          "chacha20-poly1305@openssh.com"
          "aes256-gcm@openssh.com"
          "aes128-gcm@openssh.com"
          "aes256-ctr"
          "aes192-ctr"
          "aes128-ctr"
        ];
        Macs = [
          "hmac-sha2-512-etm@openssh.com"
          "hmac-sha2-256-etm@openssh.com"
          "umac-128-etm@openssh.com"
          "hmac-sha2-512"
          "hmac-sha2-256"
          "umac-128@openssh.com"
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
    du-dust
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
