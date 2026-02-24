{
  pkgs,
  sensitive,
  ...
}: let
  netFun = import ../common/network-functions.nix;
in {
  imports = [
    ../common/network.nix
    ../common/wifi.nix
  ];
  networking = {
    hostName = "charon";
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
      hosts = [
        "tars"
        "forge"
        # "sentinel"
        "eva"
        "workstation"
        "lab"
        "bragi"
        "palantir"
        "etna"
      ];
    in
      builtins.map (name: {
        mac = sensitive.network.mac.${name}.ether;
        ip = sensitive.network.ip.${name}.lab;
      })
      hosts;
    staticDhcpLeasesCharon = let
      hosts = [
        "eva"
      ];
    in
      builtins.map (name: {
        mac = sensitive.network.mac.${name}.wifi;
        ip = sensitive.network.ip.${name}.charon;
      })
      hosts;
  in {
    wait-online = {
      enable = true;
      extraArgs = ["--interface" "wan"];
      # anyInterface = true;
    };

    # see https://docs.bisdn.de/network_configuration/vlan_bridging.html for explanation of bridgevlan option
    networks = let
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
        # NOTE: we've got a problem with 'yes' where the DHCPServer won't
        # start if there are static leases. I might have something not ok
        # with systemd-networkd-persistent-storage.
        # The lab network is mostly static, so a short lease time for floating
        # devices will avoid the likelihood of ip conflicts when the router gets
        # a rebooted and the leases are lost.
        isEmpty = l: (builtins.length l) == 0;
        persistLeases =
          if isEmpty staticDhcpLeases
          then "yes"
          else "runtime";
        leaseTime =
          if isEmpty staticDhcpLeases
          then 86400
          else 3600;
      in {
        "30-vlan-${name}" = {
          matchConfig.Name = "vlan-${name}";
          address = [
            "${sensitive.network.ip.charon.${vlan}}/24"
          ];
          networkConfig = {
            DHCPServer = true;
          };
          extraConfig = ''
            [DHCPServer]
            DefaultLeaseTimeSec = ${toString leaseTime}
            MaxLeaseTimeSec = ${toString leaseTime}
            PoolOffset = 50
            EmitDNS = true
            DNS = ${sensitive.network.dns-server vlan}
            EmitNTP = true
            NTP = ${sensitive.network.ntp-server vlan}
            PersistLeases = ${persistLeases}

            ${dhcpStaticLeasesConfig}
          '';
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
      }
      // netFun.brvlan-core-attachment {
        interface = "lan0";
        allowed_vlans = [labVlanId charonVlanId riftVlanId warpVlanId];
        pvid = labVlanId;
        egress_untagged = labVlanId;
      }
      // netFun.brvlan-core-attachment {
        interface = "lan1";
        allowed_vlans = [labVlanId charonVlanId riftVlanId warpVlanId];
        pvid = labVlanId;
        egress_untagged = labVlanId;
      }
      // netFun.brvlan-core-attachment {
        interface = "lan2";
        allowed_vlans = [labVlanId charonVlanId riftVlanId warpVlanId];
        pvid = labVlanId;
        egress_untagged = labVlanId;
      }
      // netFun.brvlan-core-attachment {
        interface = "lan3";
        allowed_vlans = [riftVlanId];
        pvid = riftVlanId;
        egress_untagged = riftVlanId;
      }
      // vlan-dhcp-configuration {
        name = "lab";
        vlan = "lab";
        staticDhcpLeases = staticDhcpLeasesLab;
      }
      // vlan-dhcp-configuration {
        name = "charon";
        vlan = "charon";
        staticDhcpLeases = staticDhcpLeasesCharon;
      }
      // vlan-dhcp-configuration {
        name = "rift";
        vlan = "rift";
      }
      // vlan-dhcp-configuration {
        name = "warp";
        vlan = "warp";
      };
  };

  # Wifi
  services.hostapd = {
    enable = true;
    radios = {
      wlan0 = {
        networks = {
          wlan0 = {
            bssid = sensitive.network.bssid.charon.wlan0-charon;
          };
          wlan0-rift = {
            bssid = sensitive.network.bssid.charon.wlan0-rift;
          };
          wlan0-warp = {
            bssid = sensitive.network.bssid.charon.wlan0-warp;
          };
        };
      };
      wlan1 = {
        networks = {
          wlan1 = {
            bssid = sensitive.network.bssid.charon.wlan1-charon;
          };
          wlan1-rift = {
            bssid = sensitive.network.bssid.charon.wlan1-rift;
          };
          wlan1-warp = {
            bssid = sensitive.network.bssid.charon.wlan1-warp;
          };
        };
      };
    };
  };
}
