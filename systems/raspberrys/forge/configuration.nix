{
  self,
  pkgs,
  config,
  modulesPath,
  sensitive,
  ...
}: let
  fluiddPort = 443;
  moonrakerPort = 7125;
in {
  imports = [
    ../common/configuration.nix
    ../common/hardware-metrics.nix
    ../common/hardware-rpi4.nix
    ../common/sops.nix
    ../common/telegraf-environment.nix
    ./sops.nix
    ./builder.nix
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
  ];
  networking = {
    hostName = "forge";
    firewall = {
      enable = true;
      allowedTCPPorts = [fluiddPort moonrakerPort];
    };
    interfaces = {
      end0 = {
        useDHCP = true;
        ipv4.addresses = [
          {
            address = sensitive.network.ip.forge;
            prefixLength = 24;
          }
        ];
      };
    };
    timeServers = [(sensitive.network.ntp-server "lab")];
    extraHosts = ''
      ${sensitive.network.ip.tars} tars.lan
    ''; # actually needed to make samba work without timeouts due to missing DNS/Gateway
  };

  environment.etc = {
    "printer/general.cfg" = {
      source = ./swx2/general.cfg;
    };
    "printer/start.cfg" = {
      source = ./swx2/start.cfg;
    };
    "printer/end.cfg" = {
      source = ./swx2/end.cfg;
    };
    "printer/macros.cfg" = {
      source = ./swx2/macros.cfg;
    };
    "printer/extruder06.cfg" = {
      source = ./swx2/extruder06.cfg;
    };
    "printer/extruder04.cfg" = {
      source = ./swx2/extruder04.cfg;
    };
    "printer/KAMP/Adaptive_Meshing.cfg" = {
      source = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/kyleisah/Klipper-Adaptive-Meshing-Purging/refs/heads/main/Configuration/Adaptive_Meshing.cfg";
        sha256 = "sha256-eczLLalk0IF01eT6ClrgwD/327UkkvRTpepDPOShOL4=";
      };
    };
    "printer/KAMP/Line_Purge.cfg" = {
      source = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/kyleisah/Klipper-Adaptive-Meshing-Purging/main/Configuration/Line_Purge.cfg";
        sha256 = "sha256-f6W2lHEPvlKIvgZQPkSoJ9YkdNebKEcm60H2WcmdZuw=";
      };
    };
    "printer/KAMP/Smart_Park.cfg" = {
      source = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/kyleisah/Klipper-Adaptive-Meshing-Purging/main/Configuration/Smart_Park.cfg";
        sha256 = "sha256-Xt2e0qjd2y09Sdegj0rvZs1lPnur7xiO24vQmK+XH8s=";
      };
    };
    "printer/KAMP/kamp.cfg" = {
      source = ./swx2/kamp.cfg;
    };
    "printer/fluidd.cfg" = {
      source =
        pkgs.fetchFromGitHub {
          owner = "fluidd-core";
          repo = "fluidd-config";
          rev = "ce48c5854e9ca3ca72b63d0327069fac20e94c7c";
          sha256 = "sha256-2sogejrM07FsKL87UMhXMPVzxErKviKN407RNo1/38I=";
        }
        + "/fluidd.cfg";
    };
    "printer/lis2dw.cfg" = {
      source = ./swx2/lis2dw.cfg;
    };
  };

  services = {
    klipper = {
      enable = true;
      user = "printer";
      group = "klipper";

      configFile = builtins.toFile "printer.cfg" ''
        ${builtins.readFile ./swx2/printer.cfg}
        [include /etc/printer/extruder04.cfg]
      '';
      mutableConfig = true;
      firmwares = {
        printer = {
          enable = true;
          enableKlipperFlash = true;
          configFile = ./printer-firmware.cfg; # generated with klipper-genconf
          serial = "/dev/serial/by-id/usb-Klipper_stm32f401xc_22004D000850435435373520-if00";
        };
        resonance = {
          enable = true;
          enableKlipperFlash = true;
          configFile = ./resonance-firmware.cfg; # generated with klipper-genconf
          serial = "/dev/serial/by-id/usb-Klipper_stm32f042x6_000024001543565537353020-if00";
        };
      };
    };
    fluidd = {
      enable = true;
      nginx = {
        forceSSL = true;
        sslCertificate = self.inputs.nixos-config-sensitive + /certificates/forge-selfsigned.crt;
        sslCertificateKey = config.sops.secrets.forge-cert-key.path;
      };
    };
    nginx = {
      clientMaxBodySize = "1000m"; # GCode can get big
    };

    moonraker = {
      user = "printer";
      group = "klipper";
      enable = true;
      address = "0.0.0.0";
      allowSystemControl = true;
      settings = {
        octoprint_compat = {};
        history = {};
        authorization = {
          force_logins = true;
          cors_domains = [
            "*.lan"
          ];
          trusted_clients = [
            (sensitive.network.vlan-range "lab")
            "127.0.0.0/24"
          ];
        };
        file_manager = {
          enable_object_processing = true;
        };
      };
    };
    # vector.package = self.outputs.nixosConfigurations.tars.config.services.vector.package;
  };

  security.polkit.enable = true;

  users.groups.klipper = {};
  users = {
    users = {
      printer = {
        isSystemUser = true;
        hashedPassword = sensitive.passwords.printer-forge;
        group = "klipper";
        openssh.authorizedKeys.keys = [
          sensitive.keys.ssh.workstation
        ];
      };
    };
  };
  environment.systemPackages = with pkgs; [
    # resonance calibration
    klipper-genconf
    (python3.withPackages (ps: with ps; [numpy matplotlib]))
    # flashing
    dfu-util
    # build inputs of klipper-firmware
    gcc
    gnumake
    pkgsCross.avr.stdenv.cc
    gcc-arm-embedded
    bintools-unwrapped
    libffi
    libusb1
    avrdude
    stm32flash
    pkg-config
    wxGTK32
  ];

  security.pki = {
    certificateFiles = [(self.inputs.nixos-config-sensitive + /certificates/tars-selfsigned.crt)];
  };

  zramSwap = {
    enable = true;
    priority = 5;
  };
  swapDevices = [
    {
      size = 16 * 1024;
      priority = 10;
      device = "/var/lib/swapfile";
      randomEncryption.enable = true;
    }
  ];

  system.stateVersion = "23.11";
}
