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
      sensitive.keys.nix.hydra-lab
    ];
    substituters = [
      "https://nix-cache.jonboh.dev"
      "https://cache.nixos.org"
    ];
  };
  configure.hardware-metrics = {
    enable = true;
    thermal_zone0-temperature.enable = true;
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

  boot.kernelPackages = pkgs.linuxKernel.packagesFor kernel;
}
