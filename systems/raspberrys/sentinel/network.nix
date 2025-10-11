{sensitive, ...}: {
  networking = {
    hostName = "sentinel";
    useDHCP = false;
    useNetworkd = true;
    firewall.enable = true;
    timeServers = [(sensitive.network.ntp-server "lab")];
    nameservers = [(sensitive.network.dns-server "lab")];
    usePredictableInterfaceNames = true;
    extraHosts = ''
      ${sensitive.network.ip.tars.lab} tars.lan
    ''; # actually needed to make samba work without timeouts due to missing DNS/Gateway on tars
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
        "30-vlan-lab" = {
          matchConfig.Name = "vlan-lab";
          address = [
            "${sensitive.network.ip.sentinel.lab}/24"
          ];
          gateway = [(sensitive.network.gateway "lab")];
        };
      };
  };
}
