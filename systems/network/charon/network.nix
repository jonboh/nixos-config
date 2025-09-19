{
  pkgs,
  config,
  sensitive,
  ...
}: {
  boot.kernel = {
    sysctl = {
      "net.ipv4.conf.all.forwarding" = true;
      "net.ipv6.conf.all.forwarding" = false;

      # Reverse Path Filtering for all interfaces
      "net.ipv4.conf.default.rp_filter" = 1;
      "net.ipv4.conf.all.rp_filter" = 1;

      # IPV6?
      # # By default, not automatically configure any IPv6 addresses.
      # "net.ipv6.conf.all.accept_ra" = 0;
      # "net.ipv6.conf.all.autoconf" = 0;
      # "net.ipv6.conf.all.use_tempaddr" = 0;
      #
      # # On WAN, allow IPv6 autoconfiguration and tempory address use.
      # "net.ipv6.conf.${name}.accept_ra" = 2;
      # "net.ipv6.conf.${name}.autoconf" = 1;
    };
  };
  networking = {
    hostName = "charon";
    useNetworkd = true;
    useDHCP = false;
    usePredictableInterfaceNames = true;
  };

  systemd.services.hostapd.before = ["systemd-networkd.service" "network.target"];
  systemd.services.reconfigure-systemd-hostapd = {
    enable = true;
    wantedBy = ["multi-user.target"];
    after = ["systemd-networkd.service" "network.target"];
    requires = ["systemd-networkd.service" "network.target"];
    script = ''
      networkctl reconfigure wlan0 wlan1 wlan0-rift wlan1-rift wlan0-warp wlan1-warp
    '';
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
  systemd.services.mirrorTraffic = let
    srcIface = "brvlan-core";
    dstIface = "lan1";
  in {
    description = "Mirror traffic between interfaces";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "setup-network-mirroring" ''
        ${pkgs.iproute2}/bin/tc qdisc add dev ${srcIface} ingress
        ${pkgs.iproute2}/bin/tc filter add dev ${srcIface} parent ffff: \
                  protocol all \
                  u32 match u8 0 0 \
                  action mirred egress mirror dev ${dstIface}

        ${pkgs.iproute2}/bin/tc qdisc add dev ${srcIface} handle 1: root prio
        ${pkgs.iproute2}/bin/tc filter add dev ${srcIface} parent 1: \
                  protocol all \
                  u32 match u8 0 0 \
                  action mirred egress mirror dev ${dstIface}
      '';
      User = "root";
      ExecStopPost = pkgs.writeShellScript "stop-network-mirroring" ''
        ${pkgs.iproute2}/bin/tc qdisc del dev ${srcIface} ingress
        ${pkgs.iproute2}/bin/tc qdisc del dev ${srcIface} root
      '';
    };
  };

  # systemd.services.hostapd.serviceConfi.ExecStartPost = [
  #       "${pkgs.systemd}/lib/systemd/systemd-networkd-wait-online -i ${cfg.interface} -o carrier"
  #       "networkctl reconfigure ${cfg.interface}" # bring up the bridge

  # see: https://www.freedesktop.org/software/systemd/man/latest/networkd.conf.html
  # systemd.services."systemd-networkd".environment.SYSTEMD_LOG_LEVEL = "debug";
  systemd.network = let
    labVlanId = sensitive.network.vlan2id.lab;
    charonVlanId = sensitive.network.vlan2id.charon;
    riftVlanId = sensitive.network.vlan2id.rift;
    warpVlanId = sensitive.network.vlan2id.warp;
    staticDhcpLeasesLab = let
      hosts = ["tars" "forge" "brick" "sentinel" "eva" "workstation"];
    in
      builtins.map (name: {
        mac = sensitive.network.mac.${name}.ether;
        ip = sensitive.network.ip.${name};
      })
      hosts;
  in {
    wait-online = {
      enable = true;
      extraArgs = ["--interface" "wan"];
      # anyInterface = true;
    };
    netdevs = let
      vlan-dev = {
        name,
        vlanid,
      }: {
        "10-vlan-${name}" = {
          netdevConfig = {
            Name = "vlan-${name}";
            Kind = "vlan";
          };
          vlanConfig = {
            Id = vlanid;
          };
        };
      };
    in
      {
        "10-brvlan-core" = {
          netdevConfig = {
            Name = "brvlan-core";
            Kind = "bridge";
          };
          bridgeConfig = {
            DefaultPVID = "none";
            VLANFiltering = true;
          };
        };
      }
      // vlan-dev {
        name = "lab";
        vlanid = labVlanId;
      }
      // vlan-dev {
        name = "charon";
        vlanid = charonVlanId;
      }
      // vlan-dev {
        name = "rift";
        vlanid = riftVlanId;
      }
      // vlan-dev {
        name = "warp";
        vlanid = warpVlanId;
      };
    # see https://docs.bisdn.de/network_configuration/vlan_bridging.html for explanation of bridgevlan option
    networks = let
      brvlan-core-attachment = {
        interface,
        allowed_vlans,
        pvid,
        egress_untagged,
      }: {
        "25-${interface}" = {
          matchConfig.Name = interface;
          linkConfig = {
            RequiredForOnline = "enslaved";
          };
          networkConfig = {
            Bridge = "brvlan-core";
            ConfigureWithoutCarrier = true;
          };
          bridgeVLANs = [
            {
              VLAN = allowed_vlans;
              PVID = pvid;
              EgressUntagged = egress_untagged;
            }
          ];
        };
      };
      vlan-dhcp-configuration = {
        name,
        vlan,
        staticDhcpLeases ? [],
      }: let
        dhcpStaticLeasesConfig = builtins.concatStringsSep "\n" (map (
            lease: ''
              [DHCPServerStaticLease]
              MACAddress=${lease.mac}
              Address=${lease.ip}
            ''
          )
          staticDhcpLeases);
      in {
        "30-vlan-${name}" = {
          matchConfig.Name = "vlan-${name}";
          address = [
            "${sensitive.network.ip.charon.${vlan}}/24"
          ];
          networkConfig = {
            DHCPServer = true;
          };
          extraConfig =
            ''
              [DHCPServer]
              DefaultLeaseTimeSec = 86400
              MaxLeaseTimeSec = 86400
              PoolOffset = 50
              EmitDNS = true
              DNS = ${sensitive.network.dns-server vlan}
              EmitNTP = true
              NTP = ${sensitive.network.ntp-server vlan}
            ''
            + "\n"
            + dhcpStaticLeasesConfig;
        };
      };
    in
      {
        # NOTE: the numbering sets the order in which networkd runs the configuration
        "10-wan" = {
          matchConfig.Name = "wan";
          networkConfig = {
            DHCP = "ipv4"; # start a DHCP Client for IPv4 Addressing/Routing
            IPv4Forwarding = true;
          };
          # Never accept ISP DNS or search domains for any DHCP/RA family.
          dhcpV4Config = {
            UseDNS = false;
            UseDomains = false;
          };
          # make routing on this interface a dependency for network-online.target
          linkConfig.RequiredForOnline = "routable";
        };
        "15-brvlan-core" = {
          matchConfig.Name = "brvlan-core";
          linkConfig.RequiredForOnline = "degraded";
          bridgeVLANs = [
            {
              VLAN = [labVlanId charonVlanId warpVlanId riftVlanId];
            }
          ];
          vlan = ["vlan-lab" "vlan-charon" "vlan-rift" "vlan-warp"];
        };
      }
      // brvlan-core-attachment {
        interface = "lan0";
        allowed_vlans = [labVlanId charonVlanId riftVlanId warpVlanId];
        pvid = labVlanId;
        egress_untagged = labVlanId;
      }
      // brvlan-core-attachment {
        interface = "lan1";
        allowed_vlans = [labVlanId charonVlanId riftVlanId warpVlanId];
        pvid = labVlanId;
        egress_untagged = labVlanId;
      }
      // brvlan-core-attachment {
        interface = "lan2";
        allowed_vlans = [riftVlanId];
        pvid = riftVlanId;
        egress_untagged = riftVlanId;
      }
      // brvlan-core-attachment {
        interface = "wlan0";
        allowed_vlans = [charonVlanId];
        pvid = charonVlanId;
        egress_untagged = charonVlanId;
      }
      // brvlan-core-attachment {
        interface = "wlan1";
        allowed_vlans = [charonVlanId];
        pvid = charonVlanId;
        egress_untagged = charonVlanId;
      }
      // brvlan-core-attachment {
        interface = "wlan0-rift";
        allowed_vlans = [riftVlanId];
        pvid = riftVlanId;
        egress_untagged = riftVlanId;
      }
      // brvlan-core-attachment {
        interface = "wlan1-rift";
        allowed_vlans = [riftVlanId];
        pvid = riftVlanId;
        egress_untagged = riftVlanId;
      }
      // brvlan-core-attachment {
        interface = "wlan0-warp";
        allowed_vlans = [warpVlanId];
        pvid = warpVlanId;
        egress_untagged = warpVlanId;
      }
      // brvlan-core-attachment {
        interface = "wlan1-warp";
        allowed_vlans = [warpVlanId];
        pvid = warpVlanId;
        egress_untagged = warpVlanId;
      }
      // vlan-dhcp-configuration {
        name = "lab";
        vlan = "lab";
        staticDhcpLeases = staticDhcpLeasesLab;
      }
      // vlan-dhcp-configuration {
        name = "charon";
        vlan = "charon";
      }
      // vlan-dhcp-configuration {
        name = "rift";
        vlan = "rift";
      }
      // vlan-dhcp-configuration {
        name = "warp";
        vlan = "warp";
      }
      // {
        # management port
        "25-lan3" = {
          matchConfig.Name = "lan3";
          linkConfig.RequiredForOnline = "no-carrier";
          networkConfig = {
            DHCPServer = true;
            ConfigureWithoutCarrier = true;
          };
          address = [
            "${sensitive.network.ip.charon.management}/24"
          ];
          extraConfig = ''
            [DHCPServer]
            DefaultLeaseTimeSec = 86400
            MaxLeaseTimeSec = 86400
            PoolOffset = 50
            EmitDNS = true
            DNS = ${sensitive.network.dns-server "mg-charon"}
            EmitNTP = true
            NTP = ${sensitive.network.ntp-server "mg-charon"}
          '';
        };
      };
  };

  # Wifi
  services.hostapd = {
    enable = true;
    radios = {
      wlan0 = {
        band = "2g";
        countryCode = "ES";
        channel = 0; # ACS (Automatic Channel Detection)

        wifi4 = {
          enable = true;
          capabilities = [
            # NOTE: use 'iw phy#1 info' to determine your VHT capabilities
            # TODO: locate where are these names defined in hostapd documentation
            "HT40+"
            "LDPC"
            "SHORT-GI-20"
            "SHORT-GI-40"
            "TX-STBC"
            "RX-STBC1"
            "MAX-AMSDU-7935"
          ];
        };
        networks = {
          wlan0 = {
            ssid = "charon";
            authentication = {
              enableRecommendedPairwiseCiphers = true;
              mode = "wpa3-sae";
              saePasswordsFile = config.sops.secrets.wifiPasswordCharon.path;
            };
            bssid = "10:1d:21:89:6a:53";
            settings = {
              ieee80211w = "1";
            };
          };
          wlan0-rift = {
            ssid = "rift";
            authentication = {
              enableRecommendedPairwiseCiphers = true;
              mode = "wpa2-sha256";
              wpaPasswordFile = config.sops.secrets.wifiPasswordRift.path;
              # saePasswordsFile = config.sops.secrets.wifiPasswordRift.path;
            };
            bssid = "90:78:37:7c:4d:b5";
            settings = {
              ieee80211w = "1";
            };
          };
          wlan0-warp = {
            ssid = "warp";
            authentication = {
              enableRecommendedPairwiseCiphers = true;
              mode = "wpa3-sae-transition";
              wpaPasswordFile = config.sops.secrets.wifiPasswordWarp.path;
              saePasswordsFile = config.sops.secrets.wifiPasswordWarp.path;
            };
            bssid = "70:97:30:68:5b:8b";
            settings = {
              ieee80211w = "1";
            };
          };
        };
      };
      wlan1 = {
        band = "5g";
        channel = 36;
        countryCode = "ES";

        # use 'iw phy#1 info' to determine your VHT capabilities
        wifi4 = {
          enable = true;
          capabilities = ["HT40+" "LDPC" "SHORT-GI-20" "SHORT-GI-40" "TX-STBC" "RX-STBC1" "MAX-AMSDU-7935"];
        };
        wifi5 = {
          enable = true;
          operatingChannelWidth = "80";
          capabilities = ["RXLDPC" "SHORT-GI-80" "SHORT-GI-160" "TX-STBC-2BY1" "SU-BEAMFORMER" "SU-BEAMFORMEE" "MU-BEAMFORMER" "MU-BEAMFORMEE" "RX-ANTENNA-PATTERN" "TX-ANTENNA-PATTERN" "RX-STBC-1" "SOUNDING-DIMENSION-4" "BF-ANTENNA-4" "VHT160" "MAX-MPDU-11454" "MAX-A-MPDU-LEN-EXP7"];
        };
        wifi6 = {
          enable = true;
          singleUserBeamformer = true;
          singleUserBeamformee = true;
          multiUserBeamformer = true;
          operatingChannelWidth = "80";
        };
        # https://w1.fi/cgit/hostap/plain/hostapd/hostapd.conf
        settings = {
          # NOTE: leave out strict (10 min listen requirement) DFS channels and channel 144, see:
          # https://bandaancha.eu/articulos/todas-canales-bandas-wifi-2-4-5-6ghz-10117
          # https://bandaancha.eu/articulos/canales-wifi-banda-5-ghz-espana-mejor-9826
          # https://avancedigital.mineco.gob.es/espectro/CNAF/notas-UN-2017.pdf
          # https://www.etsi.org/deliver/etsi_en/301800_301899/301893/02.01.01_60/en_301893v020101p.pdf
          # after testing the speed of the 80 Mhz band around 42 I get full speed, so
          # no need to touch the DFS channels, this allows the 5G radio to be online immediately
          chanlist = "36 40 44 48";
          acs_exclude_dfs = 1;
          # these two are mandatory for wifi 5 & 6 to work. They set the center of the band.
          # in my case 42 is the center of the 80 Mhz band from 36 to 48
          vht_oper_centr_freq_seg0_idx = 42;
          he_oper_centr_freq_seg0_idx = 42; # TODO: check effect

          # TODO: check the rest of parameters

          # The "tx_queue_data2_burst" parameter in Linux refers to the burst size for
          # transmitting data packets from the second data queue of a network interface.
          # It determines the number of packets that can be sent in a burst.
          # Adjusting this parameter can impact network throughput and latency.
          tx_queue_data2_burst = 2;

          # The "he_bss_color" parameter in Wi-Fi 6 (802.11ax) refers to the BSS Color field in the HE (High Efficiency) MAC header.
          # BSS Color is a mechanism introduced in Wi-Fi 6 to mitigate interference and improve network efficiency in dense deployment scenarios.
          # It allows multiple overlapping Basic Service Sets (BSS) to differentiate and coexist in the same area without causing excessive interference.
          he_bss_color = 63; # was set to 128 by openwrt but range of possible values in 2.10 is 1-63

          # Magic values that were set by openwrt but I didn't bother inspecting every single one
          he_spr_sr_control = 3;
          he_default_pe_duration = 4;
          he_rts_threshold = 1023;

          he_mu_edca_qos_info_param_count = 0;
          he_mu_edca_qos_info_q_ack = 0;
          he_mu_edca_qos_info_queue_request = 0;
          he_mu_edca_qos_info_txop_request = 0;

          # he_mu_edca_ac_be_aci=0; missing in 2.10
          he_mu_edca_ac_be_aifsn = 8;
          he_mu_edca_ac_be_ecwmin = 9;
          he_mu_edca_ac_be_ecwmax = 10;
          he_mu_edca_ac_be_timer = 255;

          he_mu_edca_ac_bk_aifsn = 15;
          he_mu_edca_ac_bk_aci = 1;
          he_mu_edca_ac_bk_ecwmin = 9;
          he_mu_edca_ac_bk_ecwmax = 10;
          he_mu_edca_ac_bk_timer = 255;

          he_mu_edca_ac_vi_ecwmin = 5;
          he_mu_edca_ac_vi_ecwmax = 7;
          he_mu_edca_ac_vi_aifsn = 5;
          he_mu_edca_ac_vi_aci = 2;
          he_mu_edca_ac_vi_timer = 255;

          he_mu_edca_ac_vo_aifsn = 5;
          he_mu_edca_ac_vo_aci = 3;
          he_mu_edca_ac_vo_ecwmin = 5;
          he_mu_edca_ac_vo_ecwmax = 7;
          he_mu_edca_ac_vo_timer = 255;
        };
        networks = {
          wlan1 = {
            ssid = "charon";
            authentication = {
              enableRecommendedPairwiseCiphers = true;
              mode = "wpa3-sae";
              saePasswordsFile = config.sops.secrets.wifiPasswordCharon.path;
            };
            bssid = "10:93:08:27:67:f9";
          };
          wlan1-rift = {
            ssid = "rift";
            authentication = {
              enableRecommendedPairwiseCiphers = true;
              mode = "wpa2-sha256";
              wpaPasswordFile = config.sops.secrets.wifiPasswordRift.path;
              # saePasswordsFile = config.sops.secrets.wifiPasswordRift.path;
            };
            bssid = "80:ec:3c:e9:88:9a";
          };
          wlan1-warp = {
            ssid = "warp";
            authentication = {
              enableRecommendedPairwiseCiphers = true;
              mode = "wpa3-sae-transition";
              wpaPasswordFile = config.sops.secrets.wifiPasswordWarp.path;
              saePasswordsFile = config.sops.secrets.wifiPasswordWarp.path;
            };
            bssid = "20:bc:e0:2c:d8:0d";
          };
        };
      };
    };
  };
  # you can probe the state with
  # `sudo iw wlan1 info`
  # NOTE: see https://github.com/NixOS/nixpkgs/issues/25378#issuecomment-1097034289
  hardware.wirelessRegulatoryDatabase = true;
  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom="ES"
  '';
}
