{
  imports = [
    ./hardware-metrics.nix
    ./wireguard-network.nix
    ./timeserver.nix
    ./smb-secrets.nix
    ./oisd-blocklist.nix
    ./vector-logging.nix
  ];
}
