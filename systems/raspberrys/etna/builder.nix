{
  config,
  sensitive,
  ...
}: {
  users.users.nixremote = {
    isNormalUser = true;
    createHome = true;
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
    settings = {
      extra-sandbox-paths = [config.programs.ccache.cacheDir];
      download-buffer-size = 524288000;
    };
    extraOptions = ''
      min-free = ${toString (16 * 1024 * 1024 * 1024)}
      max-free = ${toString (128 * 1024 * 1024 * 1024)}
    '';
  };

  programs.ccache = {
    enable = true;
    cacheDir = "/var/cache/ccache";
  };
}
