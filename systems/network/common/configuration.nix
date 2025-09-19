{
  self,
  pkgs,
  lib,
  sensitive,
  ...
}: let
  minimal_kernel = self.inputs.nixos-sbc.packages.aarch64-linux.linuxPackages_6_16_bananaPiR3_minimal.kernel;
  kernel = minimal_kernel.override (
    prev: {
      # build with ccache
      stdenv = pkgs.ccacheStdenv;
      buildPackages =
        pkgs.buildPackages
        // {
          stdenv = pkgs.ccacheStdenv;
        };

      # these are needed in order to filter traffic using tc and mirrorTrafic for suricata
      structuredExtraConfig = with lib.kernel;
        minimal_kernel.structuredExtraConfig
        // {
          NET_CLS = yes;
          NET_CLS_BASIC = module;
          NET_CLS_ROUTE4 = module;
          NET_CLS_FW = module;
          NET_CLS_U32 = module;
          NET_CLS_FLOW = module;
          NET_CLS_CGROUP = module;
          NET_CLS_BPF = module;
          NET_CLS_FLOWER = module;
          NET_CLS_MATCHALL = module;
          NET_CLS_ACT = yes;

          NET_SCH_INGRESS = module;
          NET_SCH_PRIO = module;
          NET_ACT_MIRRED = module;
        };
    }
  );
in {
  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    require-sigs = true;
    trusted-public-keys = [
      sensitive.keys.nix.workstation
      sensitive.keys.nix.brick
      sensitive.keys.nix.tars
      sensitive.keys.nix.forge
    ];
    substituters = lib.mkForce [
      # "ssh-ng://tars.lan"
      # "ssh-ng://forge.lan"
      # "ssh-ng://brick.lan"
    ];
    trusted-substituters = lib.mkForce [];
  };

  time.timeZone = "Europe/Madrid";

  users = {
    mutableUsers = false;
    users.jonboh = {
      isNormalUser = true;
      description = "jonboh";
      extraGroups = ["wheel" "network"];
      hashedPassword = sensitive.passwords.jonboh-network;
      openssh.authorizedKeys.keys = [
        sensitive.keys.ssh.workstation
      ];
    };
    users.root = {
      openssh.authorizedKeys.keys = [
        sensitive.keys.ssh.workstation
      ];
    };
  };
  security.sudo.wheelNeedsPassword = false;

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
            endpoint = "http://tars.lan:3100";
            encoding = {codec = "json";};
            labels.source = "journald";
          };
        };
      };
    };
  };

  boot.kernelPackages = pkgs.linuxKernel.packagesFor kernel;
}
