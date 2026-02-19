{
  lib,
  sensitive,
  ...
}: {
  networking = {
    hostName = "sentinel";
    useNetworkd = true;
  };

  jonboh.configure.rpiEthernet.enable = lib.mkForce false;

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
    networks = let
      brvlan-core-attachment = {
        interface,
        allowed_vlans,
        pvid,
        egress_untagged,
      }: {
        "25-${interface}" = {
          matchConfig.Name = interface;
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
    in
      {
        # NOTE: the numbering sets the order in which networkd runs the configuration
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
        interface = "end0";
        allowed_vlans = [labVlanId charonVlanId riftVlanId warpVlanId];
        pvid = labVlanId;
        egress_untagged = labVlanId;
      }
      // {
        "30-vlan-charon" = {
          matchConfig.Name = "vlan-charon";
          networkConfig.DHCP = "yes";
        };
      }
      // {
        "30-vlan-warp" = {
          matchConfig.Name = "vlan-warp";
          networkConfig.DHCP = "yes";
        };
      }
      // {
        "30-vlan-rift" = {
          matchConfig.Name = "vlan-rift";
          networkConfig.DHCP = "yes";
        };
      }
      // {
        "30-vlan-lab" = {
          matchConfig.Name = "vlan-lab";
          networkConfig.DHCP = "yes";
          address = [
            "${sensitive.network.ip.sentinel.lab}/24"
          ];
          routes = [
            {
              Gateway = sensitive.network.ip.charon.lab;
            }
          ];
        };
      };
  };
}
