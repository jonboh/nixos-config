{
  sensitive,
  pkgs,
  ...
}: {
  imports = [
    ../../common/raspberrys.nix
    ./sops.nix
    ./rp-configtxt.nix
  ];

  networking = {
    hostName = "eva";
    networkmanager = {
      enable = true;
      unmanaged = [
        "end0" # NOTE: managed with networkd
      ];
    };
    firewall = {
      allowedUDPPorts = sensitive.network.port.udp.ros-comms;
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

  users.users.jonboh.extraGroups = ["dialout" "plugdev"];

  environment.systemPackages = with pkgs; [
    git
    picocom
  ];

  system.stateVersion = "24.11";
}
