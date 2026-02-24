{sensitive, ...}: let
  netFun = import ../common/network-functions.nix;
in {
  imports = [
    ../common/network.nix
    ../common/wifi.nix
  ];
  networking = {
    hostName = "citadel";
    nat.enable = false;
    firewall.enable = false;
    nftables.enable = true;
  };

  systemd.network = let
    labVlanId = sensitive.network.vlan2id.lab;
    charonVlanId = sensitive.network.vlan2id.charon;
    riftVlanId = sensitive.network.vlan2id.rift;
    warpVlanId = sensitive.network.vlan2id.warp;
  in {
    wait-online = {
      enable = false;
      # extraArgs = ["--interface" "brvlan-core"];
    };

    networks =
      {}
      // netFun.brvlan-core-attachment {
        interface = "wan";
        allowed_vlans = [labVlanId charonVlanId riftVlanId warpVlanId];
        pvid = labVlanId;
        egress_untagged = labVlanId;
      }
      // netFun.brvlan-core-attachment {
        interface = "lan0";
        allowed_vlans = [labVlanId];
        pvid = labVlanId;
        egress_untagged = labVlanId;
      }
      // netFun.brvlan-core-attachment {
        interface = "lan1";
        allowed_vlans = [labVlanId];
        pvid = labVlanId;
        egress_untagged = labVlanId;
      }
      // netFun.brvlan-core-attachment {
        interface = "lan2";
        allowed_vlans = [labVlanId];
        pvid = labVlanId;
        egress_untagged = labVlanId;
      }
      // {
        "30-vlan-lab" = {
          matchConfig.Name = "vlan-lab";
          networkConfig.DHCP = "yes";
          address = [
            "${sensitive.network.ip.citadel.lab}/24"
          ];
        };
        "30-vlan-charon" = {
          matchConfig.Name = "vlan-charon";
          address = [
            "${sensitive.network.ip.citadel.charon}/24"
          ];
        };
        "30-vlan-rift" = {
          matchConfig.Name = "vlan-rift";
          address = [
            "${sensitive.network.ip.citadel.rift}/24"
          ];
        };
        "30-vlan-warp" = {
          matchConfig.Name = "vlan-warp";
          address = [
            "${sensitive.network.ip.citadel.warp}/24"
          ];
        };
        # management port
        "30-lan3" = {
          matchConfig.Name = "lan3";
          linkConfig.RequiredForOnline = "no-carrier";
          networkConfig = {
            DHCPServer = true;
          };
          address = [
            "${sensitive.network.ip.citadel.management}/24"
          ];
          extraConfig = ''
            [DHCPServer]
            DefaultLeaseTimeSec = 86400
            MaxLeaseTimeSec = 86400
            PoolOffset = 50
            EmitDNS = true
            DNS = ${sensitive.network.dns-server "mg-citadel"}
            EmitNTP = true
            NTP = ${sensitive.network.ntp-server "mg-citadel"}
          '';
        };
      };
  };

  services = {
    hostapd = {
      radios = {
        wlan0 = {
          networks = {
            wlan0 = {
              bssid = sensitive.network.bssid.citadel.wlan0-charon;
            };
            wlan0-rift = {
              bssid = sensitive.network.bssid.citadel.wlan0-rift;
            };
            wlan0-warp = {
              bssid = sensitive.network.bssid.citadel.wlan0-warp;
            };
          };
        };
        wlan1 = {
          networks = {
            wlan1 = {
              bssid = sensitive.network.bssid.citadel.wlan1-charon;
            };
            wlan1-rift = {
              bssid = sensitive.network.bssid.citadel.wlan1-rift;
            };
            wlan1-warp = {
              bssid = sensitive.network.bssid.citadel.wlan1-warp;
            };
          };
        };
      };
    };
  };
}
