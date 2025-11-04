{sensitive, ...}: {
  services.hydra = {
    enable = true;
    hydraURL = "http://localhost:3100"; # externally visible URL
    notificationSender = "hydra@localhost"; # e-mail of Hydra service
    # you will probably also want this, otherwise *everything* will be built from scratch
    useSubstitutes = true;
    port = 3100;
    minimumDiskFree = 20;
    minimumDiskFreeEvaluator = 20;
    extraConfig = ''
      max_unsupported_time = 604800
    '';
  };

  programs.ssh.knownHosts = {
    "tars.lan" = {
      publicKey = sensitive.keys.ssh-host.tars;
    };
  };
  nix.settings.allowed-uris = [
    "github:"
    "git+https://github.com/"
    "git+ssh://github.com/"
    "git+ssh://tars.lan/"
  ];
}
