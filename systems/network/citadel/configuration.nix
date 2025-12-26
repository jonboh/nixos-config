{
  self,
  pkgs,
  sensitive,
  ...
}: {
  imports = [
    ./network.nix

    ../common/sops.nix
    ../../common/network.nix
  ];

  configure.ntpd-rs.enable = true;

  environment.systemPackages = with pkgs; [
    jq

    bottom # replacement of htop/nmon
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
    which
    tree
    gnused
    gnutar
    gawk

    iw # for determining VHT capabilities (wifi)
  ];
  system.stateVersion = "24.11";
}
