{
  pkgs,
  sensitive,
  ...
}: {
  imports = [
    ../../common/raspberrys.nix
    ./sops.nix
    ./rp-configtxt.nix
    ./builder.nix
    ./kernel.nix
  ];
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

  fileSystems."/nix" = {
    device = "/dev/disk/by-label/etna-store";
    fsType = "ext4";
    neededForBoot = true;
    options = ["noatime"];
  };

  networking = {
    hostName = "etna";
    useDHCP = true;
    interfaces.end0.useDHCP = true;
  };

  zramSwap = {
    enable = true;
    priority = 20;
  };
  swapDevices = [
    {
      size = 16 * 1024;
      priority = 10;
      device = "/var/lib/swapfile";
      randomEncryption.enable = true;
    }
  ];
  boot.kernelParams = [
    "zswap.enabled=1" # enables zswap
    "zswap.compressor=lz4" # compression algorithm
    "zswap.max_pool_percent=20" # maximum percentage of RAM that zswap is allowed to use
    "zswap.shrinker_enabled=1" # whether to shrink the pool proactively on high memory pressure
  ];

  system.stateVersion = "25.11";
}
