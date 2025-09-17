{
  pkgs,
  sensitive,
  ...
}: {
  networking.nameservers = ["127.0.0.1"];
  services = {
    resolved.enable = false; # disable, we use dnscrypt instead

    dnscrypt-proxy2 = {
      enable = true;
      settings = {
        listen_addresses = ["0.0.0.0:53"];
        # Use servers reachable over IPv4
        ipv4_servers = true;
        # Use servers reachable over IPv6 -- Do not enable if you don't have IPv6 connectivity
        ipv6_servers = true;
        block_ipv6 = false;
        # Use servers implementing the DNSCrypt protocol
        dnscrypt_servers = true;
        # Use servers implementing the DNS-over-HTTPS protocol
        doh_servers = false;
        # Do not use servers implementing the Oblivious DNS-over-HTTPS protocol
        odoh_servers = false;
        # Server must support DNS security extensions (DNSSEC)
        require_dnssec = true;
        # Server must not log user queries (declarative)
        require_nolog = true;
        # Server must not enforce its own blacklist (for parental control, ads blocking...)
        require_nofilter = true;
        # disable servers we use as relays
        disabled_server_names = ["cs-fr" "cs-barcelona"];
        anonymized_dns = {
          routes = [
            {
              server_name = "*";
              via = ["anon-cs-fr" "anon-cs-barcelona"];
            }
          ];
          # Skip resolvers incompatible with anonymization instead of using them directly
          skip_incompatible = true;
        };

        sources = {
          public-resolvers = {
            urls = [
              "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
              "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
            ];
            cache_file = "/var/lib/dnscrypt-proxy/public-resolvers.md";
            minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
          };
          relays = {
            urls = [
              "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/relays.md"
            ];
            cache_file = "/var/lib/dnscrypt-proxy/relays.md";
            minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3"; # NOTE: key from https://github.com/DNSCrypt/dnscrypt-proxy/wiki/DNS-server-sources
          };
        };
        cloaking_rules = pkgs.writeTextFile {
          name = "cloaking_rules.txt";
          text = ''
            charon.lan ${sensitive.network.ip.charon.lab}
            citadel.lan ${sensitive.network.ip.citadel.lab}
            lab.lan ${sensitive.network.ip.lab}
            tars.lan ${sensitive.network.ip.tars}
            forge.lan ${sensitive.network.ip.forge}
            brick.lan ${sensitive.network.ip.brick}
            sentinel.lan ${sensitive.network.ip.sentinel}
            eva.lan ${sensitive.network.ip.eva}
            iaq-lab.lan ${sensitive.network.ip.iaq-lab}
            iaq-bedroom.lan ${sensitive.network.ip.iaq-bedroom}
            iaq-outside.lan ${sensitive.network.ip.iaq-outside}
          '';
        };

        blocked_names.blocked_names_file = builtins.fetchurl {
          url = "https://nsfw.oisd.nl/domainswild";
          sha256 = "sha256:1jba5hb7xvp0vbnc4cqgqja2k4nj9mxzyyjn6a4hg99cknxr456r";
        };
      };
    };
  };
  systemd.services.dnscrypt-proxy2.serviceConfig = {
    StateDirectory = "dnscrypt-proxy";
  };
}
