{
  pkgs,
  sensitive,
  ...
}: {
  imports = [
    ../../common/raspberrys.nix
    ./network.nix
    ./sops.nix
    ./rp-configtxt.nix
  ];

  jonboh.configure = {
    ntpd-rs.source = "internet"; # this machine does not have acesss to my local network
    wireguard = {
      enable = true;
      deviceName = "thule";
      allowedNetworks = ["viae" "hodos"];
      keepAlive = true;
    };
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
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
  };
  boot.kernelParams = [
    "zswap.enabled=1" # enables zswap
    "zswap.compressor=lz4" # compression algorithm
    "zswap.max_pool_percent=20" # maximum percentage of RAM that zswap is allowed to use
    "zswap.shrinker_enabled=1" # whether to shrink the pool proactively on high memory pressure
  ];

  users.users.borgremote = {
    isNormalUser = true;
    createHome = true;
    openssh.authorizedKeys.keys = [
      sensitive.keys.ssh.workstation
      sensitive.keys.ssh."root@lab"
      sensitive.keys.ssh."root@bragi"
      sensitive.keys.ssh."root@tars"
    ];
  };

  fileSystems = {
    "/mnt/storage" = {
      device = "/dev/disk/by-label/wolf81";
      fsType = "ext4";
    };
  };

  environment.systemPackages = with pkgs; [
    borgbackup
  ];

  system.stateVersion = "25.11";
}
