{
  self,
  config,
  pkgs,
  sensitive,
  ...
}: {
  imports = [
    ../common/configuration.nix
    ./sops.nix
    ./rp-configtxt.nix
  ];
  # bcm2711 for rpi 3, 3+, 4, zero 2 w
  # bcm2712 for rpi 5
  # See the docs at:
  # https://www.raspberrypi.com/documentation/computers/linux_kernel.html#native-build-configuration
  raspberry-pi-nix.board = "bcm2712";

  configure.hardware-metrics = {
    enable = true;
    thermal_zone0-temperature.enable = true;
  };

  boot.initrd.checkJournalingFS = false; # manually done on PostDeviceCommand
  boot.initrd.enable = true;
  boot.initrd.postDeviceCommands = ''
    info "Repairing all filesystems"
    fsck -A -y -V
  '';

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
    hostName = "brick";
    # networkmanager.enable = true;
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
            address = sensitive.network.ip.brick.lab;
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
  ];

  system.stateVersion = "24.11";
}
