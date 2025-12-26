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
  services.ntpd-rs = {
    enable = true;
    settings = {
      source = [
        {
          address = "0.nixos.pool.ntp.org";
          mode = "pool";
        }
        {
          address = "1.nixos.pool.ntp.org";
          mode = "pool";
        }
        {
          address = "2.nixos.pool.ntp.org";
          mode = "pool";
        }
        {
          address = "3.nixos.pool.ntp.org";
          mode = "pool";
        }
        {
          address = "ntpd-rs.pool.ntp.org";
          mode = "pool";
        }
        # source: https://wiki.bandaancha.st/Lista_de_servidores_NTP_stratum_1_en_Espa%C3%B1a
        {
          address = "130.206.3.166";
          mode = "server";
        }
        {
          address = "130.206.0.1";
          mode = "server";
        }
        {
          address = "150.214.94.5";
          mode = "server";
        }
        {
          address = "150.214.94.10";
          mode = "server";
        }
        {
          address = "193.147.107.33";
          mode = "server";
        }
        {
          address = "185.179.104.7";
          mode = "server";
        }
        {
          address = "185.179.104.12";
          mode = "server";
        }
        {
          address = "150.214.5.121";
          mode = "server";
        }
        {
          address = "158.227.98.15";
          mode = "server";
        }
      ];
      server = [
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
    };
    settings = {
      observability.ansi-colors = false;
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
