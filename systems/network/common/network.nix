{sensitive, ...}: let
  netFun = import ../common/network-functions.nix;

  labVlanId = sensitive.network.vlan2id.lab;
  charonVlanId = sensitive.network.vlan2id.charon;
  riftVlanId = sensitive.network.vlan2id.rift;
  warpVlanId = sensitive.network.vlan2id.warp;
in {
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

  systemd.network.netdevs =
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
    // netFun.vlan-dev {
      name = "lab";
      vlanid = labVlanId;
    }
    // netFun.vlan-dev {
      name = "charon";
      vlanid = charonVlanId;
    }
    // netFun.vlan-dev {
      name = "rift";
      vlanid = riftVlanId;
    }
    // netFun.vlan-dev {
      name = "warp";
      vlanid = warpVlanId;
    };

  systemd.network.networks =
    {
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
    // netFun.brvlan-core-attachment {
      interface = "wlan0";
      allowed_vlans = [charonVlanId];
      pvid = charonVlanId;
      egress_untagged = charonVlanId;
    }
    // netFun.brvlan-core-attachment {
      interface = "wlan1";
      allowed_vlans = [charonVlanId];
      pvid = charonVlanId;
      egress_untagged = charonVlanId;
    }
    // netFun.brvlan-core-attachment {
      interface = "wlan0-rift";
      allowed_vlans = [riftVlanId];
      pvid = riftVlanId;
      egress_untagged = riftVlanId;
    }
    // netFun.brvlan-core-attachment {
      interface = "wlan1-rift";
      allowed_vlans = [riftVlanId];
      pvid = riftVlanId;
      egress_untagged = riftVlanId;
    }
    // netFun.brvlan-core-attachment {
      interface = "wlan0-warp";
      allowed_vlans = [warpVlanId];
      pvid = warpVlanId;
      egress_untagged = warpVlanId;
    }
    // netFun.brvlan-core-attachment {
      interface = "wlan1-warp";
      allowed_vlans = [warpVlanId];
      pvid = warpVlanId;
      egress_untagged = warpVlanId;
    };
}
