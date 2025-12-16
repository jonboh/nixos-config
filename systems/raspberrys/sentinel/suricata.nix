{sensitive, ...}: {
  services.suricata = {
    enable = true;
    settings = {
      vars.address-groups.HOME_NET = "[${sensitive.network.vlan-range "lab"},${sensitive.network.vlan-range "charon"},${sensitive.network.wg-range "viae"}]"; # TODO: add the rest of network segments
      outputs = [
        {
          stats = {
            enabled = true;
            filename = "stats.log";
            append = "yes";
            totals = "yes";
            threads = "no";
            null-values = "yes";
          };
        }
        {
          fast = {
            enabled = true;
            filename = "fast.log";
            append = "yes";
          };
        }
        {
          eve-log = {
            # see https://docs.suricata.io/en/latest/output/eve/eve-json-output.html
            enabled = true;
            filetype = "regular";
            filename = "eve.json";
            community-id = true;
            types = [
              {
                # files = {
                #   force-magic = "no";
                #   memcap = "8mb";
                # };
                alert.tagged-packets = "yes";
                anomaly.enabled = "yes";
                http.extended = "yes";
                dns.enabled = "yes";
                tls.extended = "yes";
                smtp.enabled = "yes";
                ftp.enabled = "yes";
                rdp.enabled = "yes";
                nfs.enabled = "yes";
                smb.enabled = "yes";
                tftp.enabled = "yes";
                ike.enabled = "yes";
                dcercp.enabled = "yes";
                krb5.enabled = "yes";
                bittorrent-dht.enabled = "yes";
                snmp.enabled = "yes";
                rfb.enabled = "yes";
                sip.enabled = "yes";
                quic.enabled = "yes";
                dhcp.enabled = "yes";
                ssh.enabled = "yes";
                mqtt.enabled = "yes";
                http2.enabled = "yes";
                flow.enabled = "yes";
                stats.totals = "yes";
              }
            ];
          };
        }
      ];
      af-packet = [
        {
          interface = "vlan-lab";
          defrag = true;
          cluster-id = 99;
        }
        {
          interface = "vlan-charon";
          defrag = true;
          cluster-id = 98;
        }
        {
          interface = "vlan-rift";
          defrag = true;
          cluster-id = 97;
        }
        {
          interface = "vlan-warp";
          defrag = true;
          cluster-id = 96;
        }
      ];
      af-xdp = [];
      dpdk.interfaces = [];
      pcap = [];
      app-layer.protocols.modbus.enabled = "yes";
      logging = {
        outputs = {
          console.enable = true;
          file = {
            enable = true;
          };
        };
      };
      stats = {
        enable = true;
      };
    };
  };
}
