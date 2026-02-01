{
  config,
  sensitive,
  ...
}: {
  users.users.nixremote = {
    isNormalUser = true;
    createHome = false;
    openssh.authorizedKeys.keys = [
      sensitive.keys.ssh.root-workstation
      sensitive.keys.ssh.workstation
    ];
  };
  users.groups.nixremote = {};

  nix = {
    nrBuildUsers = 64;
    settings = {
      trusted-users = ["nixremote"];
    };
    optimise = {
      automatic = true;
      dates = ["03:45"];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  programs.ccache = {
    enable = true;
    cacheDir = "/var/cache/ccache";
  };
  nix.settings.extra-sandbox-paths = [config.programs.ccache.cacheDir];
}
