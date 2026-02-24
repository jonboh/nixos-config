{
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
}
