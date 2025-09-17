{
  self,
  pkgs,
  sensitive,
  ...
}: {
  imports = [
    ../common/configuration.nix
    ../common/telegraf-environment.nix
    ../common/hardware-metrics.nix
    ../common/sops.nix
    ./sops.nix
    ./rp-configtxt.nix
    ./network.nix
  ];
  # bcm2711 for rpi 3, 3+, 4, zero 2 w
  # bcm2712 for rpi 5
  # See the docs at:
  # https://www.raspberrypi.com/documentation/computers/linux_kernel.html#native-build-configuration
  raspberry-pi-nix.board = "bcm2712";

  systemd.services.rp-fancontrol = {
    enable = true;
    description = "RPi GPIO fan control service";
    after = ["multi-user.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      ExecStart = "${pkgs.rp-fancontrol}/bin/rp-fancontrol --temp 50 --pwm 0 --temp 55 --pwm 0.5 --temp 60 --pwm 0.7 --temp 70 --pwm 1";
      Type = "simple";
      Restart = "always";
      RestartSec = "5";
    };
  };

  zramSwap = {
    enable = true;
    priority = 5;
  };
  swapDevices = [
    {
      size = 4 * 1024;
      priority = 10;
      device = "/var/lib/swapfile";
      randomEncryption.enable = true;
    }
  ];

  services.suricata = {
    enable = true;
    settings = {
      vars.address-groups.HOME_NET = "[${sensitive.network.vlan-range "lab"},${sensitive.network.vlan-range "charon"}]"; # TODO: add the rest of network segments
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

  services.vector.settings.sources.eve_json = {
    type = "file";
    include = ["/var/log/suricata/eve.json"];
    read_from = "beginning";
  };
  services.vector.settings.sinks.loki_eve = {
    type = "loki";
    inputs = ["eve_json"];
    endpoint = "http://tars.lan:3100";
    encoding = {codec = "json";};
    labels.source = "eve_json";
  };

  environment.systemPackages = with pkgs; [
    emacs
    git
    wget
    tcpdump
  ];
  security.pki = {
    certificateFiles = [(self.inputs.nixos-config-sensitive + /certificates/tars-selfsigned.crt)];
  };

  system.stateVersion = "24.11";
}
