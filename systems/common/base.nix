{
  pkgs,
  lib,
  sensitive,
  ...
}: {
  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      trusted-users = ["root" "@wheel"];
      trusted-public-keys = [
        sensitive.keys.nix.workstation
        sensitive.keys.nix.hydra-lab
      ];
      substituters = [
        "https://nix-cache.jonboh.dev"
        "https://cache.nixos.org"
      ];
      allow-import-from-derivation = true;
      require-sigs = true;
    };
    package = pkgs.nixVersions.latest;
  };

  configure = {
    hardware-metrics = {
      enable = true;
    };
    vector-logging.enable = true;
  };

  time.timeZone = "Europe/Madrid";
  i18n.defaultLocale = "en_US.UTF-8";

  users.users.jonboh = {
    isNormalUser = true;
    description = "jonboh";
    extraGroups = ["wheel"];
    uid = 1000;
  };

  networking.firewall.enable = lib.mkDefault true;

  environment.pathsToLink = [
    # link all /share and /bin folders from packages into /run/current-system/sw/
    "/share"
    "/bin"
  ];

  # Base system packages available on all systems
  environment.systemPackages = with pkgs; [
    vim
    htop
  ];
}
