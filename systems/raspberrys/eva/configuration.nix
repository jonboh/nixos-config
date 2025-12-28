{sensitive, ...}: {
  imports = [
    ../../common/raspberrys.nix
    ./sops.nix
    # ./rp-configtxt.nix
  ];

  networking = {
    hostName = "eva";
    firewall = {
      enable = true;
    };
    interfaces = {
      end0 = {
        useDHCP = true;
        ipv4.addresses = [
          {
            address = sensitive.network.ip.eva.lab;
            prefixLength = 24;
          }
        ];
      };
    };
    timeServers = [(sensitive.network.ntp-server "lab")];
    defaultGateway = sensitive.network.gateway "lab";
    extraHosts = ''
      ${sensitive.network.ip.tars.lab} tars.lan
    ''; # actually needed to make samba work without timeouts due to missing DNS/Gateway
  };

  system.stateVersion = "24.11";
}
