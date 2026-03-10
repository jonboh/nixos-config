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

            # ICMPv4/6.
            ${icmp_rules}

            # Drop and log everything else
            log prefix "nftables, input, drop, unmatched, " level warn flags all;
            counter drop
          }

          chain forward {
            type filter hook forward priority filter; policy accept;

            iifname {"vlan-lab", "vlan-charon", "vlan-rift", "vlan-warp"} oifname { "vlan-lab" } udp dport 123 accept comment "ntp"

            # lan0: lab
            ## lab itself
            iifname { "vlan-lab" } accept comment "Allow traffic coming from lan0"
            oifname { "vlan-lab" } ct state { established, related } accept comment "Allow established back to lab"

            # Allow devices on warp to connect to home-assistant
            iifname { "vlan-warp" } oifname { "vlan-lab" } ip daddr ${sensitive.network.ip.bragi.lab} tcp dport { 80, 443 } accept comment "Allow traffic coming from lan0 on ports 80 and 443"
            iifname { "vlan-warp" } oifname { "vlan-lab" } ip saddr ${sensitive.network.ip.bragi.lab} ct state { established, related } tcp sport { 80, 443 } accept comment "Allow established back to lab on ports 80 and 443"

            # lan1: alba's office
            iifname { "lan1" } oifname { "wan" } accept comment "Allow albas to go to wan"
            iifname { "wan" } oifname { "lan1" } ct state { established, related } accept comment "Allow established traffic from WAN back to albas"

            # # charon wifi
            iifname { "vlan-charon" } oifname { "vlan-lab" } accept comment "Allow charon to lab"
            oifname { "vlan-charon" } iifname { "vlan-lab" } ct state { established, related } comment "Allow established connection from lab back to charon"
            iifname { "vlan-charon" } oifname { "wan" } accept comment "Allow charon to WAN"
            iifname { "wan" } oifname { "vlan-charon" } ct state { established, related } accept comment "Allow established traffic from WAN back to charon wifi"

            # rift wifi
            iifname { "vlan-rift" } oifname { "wan" } accept comment "Allow rift to WAN"
            iifname { "wan" } oifname { "vlan-rift" } ct state { established, related } accept comment "Allow established traffic from WAN back to rift wifi"
            # allow samba (tv data)
            iifname { "vlan-rift" } ip daddr { ${sensitive.network.ip.bragi.lab} } tcp dport {445} accept comment "Allow rift to bragi services"
            oifname { "vlan-rift" } ip saddr { ${sensitive.network.ip.bragi.lab} } tcp sport 445 ct state { established, related } comment "Allow established connection from services back to rift"
            # allow samba (galadriels data)
            iifname { "vlan-rift" } ip daddr { ${sensitive.network.ip.lab.lab} } tcp dport {445} accept comment "Allow charon to tars services"
            oifname { "vlan-rift" } ip saddr { ${sensitive.network.ip.lab.lab} } tcp sport 445 ct state { established, related } comment "Allow established connection from services back to warp"

            # warp wifi forwarding will be blocked by default policy
            # allow mqtt
            iifname { "vlan-warp" } ip daddr { ${sensitive.network.ip.tars.lab} } tcp dport 1883 accept comment "Allow warp to tars services"
            oifname { "vlan-warp" } ip saddr { ${sensitive.network.ip.tars.lab} } tcp sport 1883 ct state { established, related } comment "Allow established connection from services back to warp"

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
