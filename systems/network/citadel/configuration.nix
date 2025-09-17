{
  self,
  pkgs,
  sensitive,
  ...
}: {
  imports = [
    ./network.nix

    ../common/sops.nix
    ../common/telegraf.nix
    ../common/telegraf-environment.nix
    ../common/configuration.nix
  ];

  services.ntpd-rs = {
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

  environment.systemPackages = with pkgs; [
    vim
    jq

    bottom # replacement of htop/nmon
    htop
    iotop
    iftop
    nmon

    # system call monitoring
    strace
    ltrace # library call monitoring
    lsof

    mtr # A network diagnostic tool
    iperf3 # A tool for measuring TCP and UDP bandwidth performance
    nmap # A utility for network discovery and security auditing
    ldns # replacement of dig, it provide the command `drill`
    socat # replacement of openbsd-netcat
    tcpdump # A powerful command-line packet analyzer
    ethtool # manage NIC settings (offload, NIC feeatures, ...)
    dnsutils # dig
    wavemon # Ncurses-based monitoring application for wireless network devices

    # system tools
    sysstat
    lm_sensors # for `sensors` command
    pciutils
    lshw

    # misc
    file
    which
    tree
    gnused
    gnutar
    gawk

    iw # for determining VHT capabilities (wifi)
  ];
  system.stateVersion = "24.11";
}
