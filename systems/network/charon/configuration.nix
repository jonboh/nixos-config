{
  pkgs,
  sensitive,
  ...
}: {
  imports = [
    ./network.nix
    ./nftables.nix
    ./dns.nix

    ../common/sops.nix
    ../../common/network.nix
  ];

  # Time server for local nework
  jonboh.configure.ntpd-rs = {
    enable = true;
    source = "local"; # forward the lab ntp into the rest of the network
  };
  services.ntpd-rs.settings.server = [
    {
      listen = "${sensitive.network.ip.charon.lab}:123";
    }
    {
      listen = "${sensitive.network.ip.charon.charon}:123";
    }
    {
      listen = "${sensitive.network.ip.charon.warp}:123";
    }
    {
      listen = "${sensitive.network.ip.charon.rift}:123";
    }
  ];

  zramSwap = {
    enable = true;
    priority = 20;
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

    ntp

    iw # for determining VHT capabilities (wifi)
  ];

  system.stateVersion = "24.11";
}
