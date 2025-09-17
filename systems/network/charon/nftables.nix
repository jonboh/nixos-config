# structurally inspired by https://github.com/mdlayher/homelab/blob/main/nixos/routnerr-3/nftables.nix
{
  lib,
  sensitive,
  ...
}: let
  # ICMP filtering.
  icmp_rules = ''
    ip6 nexthdr icmpv6 icmpv6 type {
      echo-request,
      echo-reply,
      destination-unreachable,
      packet-too-big,
      time-exceeded,
      parameter-problem,
      nd-neighbor-solicit,
      nd-neighbor-advert,
    } counter accept

    ip protocol icmp icmp type {
      echo-request,
      echo-reply,
      destination-unreachable,
      time-exceeded,
      parameter-problem,
    } counter accept
  '';

  # Produces a CSV list of interface names.
  mkCSV = lib.concatMapStrings (ifi: "${ifi.name}, ");

  ports = {
    dns = "53";
    dhcp4_server = "67";
    dhcp4_client = "68";
  };
in {
  networking = {
    # using nftables
    nat.enable = false;
    firewall.enable = false;

    nftables = {
      enable = true;
      # TODO: rules for all networks
      ruleset = ''
        table inet filter {

          chain input {
            type filter hook input priority 0; policy drop;

            ct state {established, related} counter accept comment "Accept established traffic back to the router"
            ct state invalid counter log prefix "nftables, input, drop, invalid, " level warn flags all drop

            iifname "lo" accept
            iifname "lan3" accept

            # Accept DNS over TCP for both IPv4 and IPv6
            iifname { "vlan-lab", "vlan-charon", "vlan-rift", "vlan-warp" } tcp dport ${ports.dns} accept
            # Accept DNS over UDP for both IPv4 and IPv6
            iifname { "vlan-lab", "vlan-charon", "vlan-rift", "vlan-warp" } udp dport ${ports.dns} accept
            # Accept DHCPv4 requests and DHCPv6 communications on the respective ports
            iifname { "vlan-lab", "vlan-charon", "vlan-rift", "vlan-warp" } udp dport { 67, 546, 547 } accept

            iifname "vlan-lab" tcp dport 22 accept comment "ssh"
            iifname {"vlan-lab", "vlan-charon", "vlan-rift", "vlan-warp"} udp dport 123 accept comment "ntp"

            # ICMPv4/6.
            ${icmp_rules}

            # Drop and log everything else
            log prefix "nftables, input, drop, unmatched, " level warn flags all;
            counter drop
          }

          chain forward {
            type filter hook forward priority filter; policy accept;

            iifname "lan3" counter log prefix "nftables, forward, drop, lan3" level warn flags all drop

            # lan0: lab
            ## lab services
            ip saddr { ${sensitive.network.ip.tars}, ${sensitive.network.ip.forge} } oifname { "wan" } drop comment "Block traffic from services to wan"
            ip daddr { ${sensitive.network.ip.tars}, ${sensitive.network.ip.forge} } iifname { "wan" } drop comment "Block traffic to services from wan"
            ## lab itself
            iifname { "vlan-lab" } accept comment "Allow traffic coming from lan0"
            oifname { "vlan-lab" } ct state { established, related } accept comment "Allow established back to lab"

            # lan1: alba's office
            iifname { "lan1" } oifname { "wan" } accept comment "Allow albas to go to wan"
            iifname { "wan" } oifname { "lan1" } ct state { established, related } accept comment "Allow established traffic from WAN back to albas"

            # # charon wifi
            iifname { "vlan-charon" } ip daddr { ${sensitive.network.ip.tars} } accept comment "Allow charon to tars services"
            iifname { "vlan-charon" } ip daddr { ${sensitive.network.ip.forge} } accept comment "Allow charon to forge services"
            oifname { "vlan-charon" } ip saddr { ${sensitive.network.ip.tars} } ct state { established, related } comment "Allow established connection from tars services back to charon"
            oifname { "vlan-charon" } ip saddr { ${sensitive.network.ip.forge} } ct state { established, related } comment "Allow established connection from forge services back to charon"
            iifname { "vlan-charon" } oifname { "wan" } accept comment "Allow charon to WAN"
            iifname { "wan" } oifname { "vlan-charon" } ct state { established, related } accept comment "Allow established traffic from WAN back to charon wifi"

            # rift wifi
            iifname { "vlan-rift" } oifname { "wan" } accept comment "Allow rift to WAN"
            iifname { "wan" } oifname { "vlan-rift" } ct state { established, related } accept comment "Allow established traffic from WAN back to rift wifi"
            # allow samba
            iifname { "vlan-rift" } ip daddr { ${sensitive.network.ip.tars} } tcp dport {445} accept comment "Allow charon to tars services"
            oifname { "vlan-rift" } ip saddr { ${sensitive.network.ip.tars} } tcp sport 445 ct state { established, related } comment "Allow established connection from services back to warp"
            # allow steamlink to workstation
            iifname { "vlan-rift" } ip daddr { ${sensitive.network.ip.workstation} } tcp dport {27036, 27037} accept comment "Allow rift to workstation steam"
            oifname { "vlan-rift" } ip saddr { ${sensitive.network.ip.workstation} } tcp sport {27036, 27037} ct state { established, related } comment "Allow established connection from rift back to workstation"
            iifname { "vlan-rift" } ip daddr { ${sensitive.network.ip.workstation} } udp dport {27031, 27036, 10400, 10401} accept comment "Allow rift to workstation steam"

            # warp wifi forwarding will be blocked by default policy
            # allow mqtt
            iifname { "vlan-warp" } ip daddr { ${sensitive.network.ip.tars} } tcp dport 1883 accept comment "Allow warp to tars services"
            oifname { "vlan-warp" } ip saddr { ${sensitive.network.ip.tars} } tcp sport 1883 ct state { established, related } comment "Allow established connection from services back to warp"

            log prefix "nftables, input, drop, unmatched, " level warn flags all;
            counter drop
          }
        }

        table ip nat {
          chain postrouting {
            type nat hook postrouting priority 100; policy accept;
            oifname "wan" masquerade
          }
        }
      '';
    };
  };
}
