{
  self,
  config,
  pkgs,
  sensitive,
  ...
}: {
  imports = [
    ../common/configuration.nix
    ../common/hardware-metrics.nix
    ./sops.nix
    ./builder.nix
    ./rp-configtxt.nix
    ./filesystems.nix
    ./kernel.nix
  ];

  boot.initrd.checkJournalingFS = false; # manually done on PostDeviceCommand
  boot.initrd.enable = true;
  boot.initrd.postDeviceCommands = ''
    info "Repairing all filesystems"
    fsck -A -y -V
  '';

  services.xserver = {
    enable = true;
    displayManager.lightdm.enable = true;
    desktopManager.xfce.enable = true;
  };

  systemd.services.rp-fancontrol = {
    enable = true;
    description = "RPi GPIO fan control service";
    after = ["multi-user.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      ExecStart = "${pkgs.rp-fancontrol}/bin/rp-fancontrol --temp 50 --pwm 0 --temp 55 --pwm 0.5 --temp 60 --pwm 0.7 --temp 70 --pwm 1";
      Type = "simple";
      Restart = "always";
      RestartSec = "5";
    };
  };

  networking = {
    hostName = "palantir";
    networkmanager.enable = true;
    firewall = {
      enable = true;
    };
    # wireless = {
    #   enable = true;
    #   # fallbackToWPA2 = false;
    #   secretsFile = config.sops.templates.charon_psk.path;
    #
    #   networks."charon".pskRaw = "ext:psk_charon";
    # };
    # TODO: fix configuration, wlan0 does not seem to work unless
    interfaces = {
      end0 = {
        useDHCP = true;
        ipv4.addresses = [
          {
            address = sensitive.network.ip.palantir.lab;
            prefixLength = 24;
          }
        ];
      };
      # wlan0 = {
      #   useDHCP = true;
      # };
    };
    extraHosts = ''
      ${sensitive.network.ip.tars.lab} tars.lan
    ''; # actually needed to make samba work without timeouts due to missing DNS/Gateway on tars
  };

  environment.systemPackages = with pkgs; [
    git
    wget
    moonlight-qt
    mesa
    ffmpeg-full
  ];
  boot.kernelModules = ["bcm2835-codec" "videodev"];

  system.stateVersion = "24.11";
}
