{
  pkgs,
  config,
  sensitive,
  ...
}: {
  imports = [./builder.nix];
  services.hydra = {
    enable = true;
    hydraURL = "https://hydra.jonboh.dev";
    notificationSender = "hydra@jonboh.dev";
    useSubstitutes = true;
    port = 3100;
    listenHost = "127.0.0.1";

    minimumDiskFree = 20;
    minimumDiskFreeEvaluator = 20;
    extraConfig = ''
      max_unsupported_time = 604800
      allow_import_from_derivation = true
    '';
  };
  networking.firewall.allowedTCPPorts = [80 443];

  programs.ssh.knownHosts = {
    "etna.lan" = {
      publicKey = sensitive.keys.ssh-host.etna;
    };
  };
  nix.settings.allowed-uris = [
    "github:"
    "git+https://github.com/"
    "git+ssh://github.com/"
    "git+ssh://tars.lan/"
  ];

  services = {
    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedBrotliSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
        "hydra.jonboh.dev" = {
          listen = [
            {
              addr = "0.0.0.0";
              port = 80;
              ssl = false;
            }
            {
              port = 443;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          forceSSL = true;
          sslCertificate = "/var/lib/acme/jonboh.dev/fullchain.pem";
          sslCertificateKey = "/var/lib/acme/jonboh.dev/key.pem";
          locations."/" = {
            proxyPass = "http://127.0.0.1:3100";
          };
        };
        "nix-cache.jonboh.dev" = {
          listen = [
            {
              addr = "0.0.0.0";
              port = 80;
              ssl = false;
            }
            {
              port = 443;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          forceSSL = true;
          sslCertificate = "/var/lib/acme/jonboh.dev/fullchain.pem";
          sslCertificateKey = "/var/lib/acme/jonboh.dev/key.pem";
          locations."/" = {
            proxyPass = "http://${config.services.nix-serve.bindAddress}:${toString config.services.nix-serve.port}";
          };
        };
      };
    };
  };
  users.users.nginx.extraGroups = ["acme"];
  security.acme = {
    acceptTerms = true;
    defaults.email = "jon.bosque.hernando@gmail.com";
    certs."jonboh.dev" = {
      domain = "*.jonboh.dev";
      dnsProvider = "rfc2136";
      environmentFile = config.sops.secrets.certs-secrets.path;
      dnsPropagationCheck = false;
      # server = "https://acme-staging-v02.api.letsencrypt.org/directory"; # NOTE: use this for debugging
      validMinDays = 90;
    };
  };

  nix.settings = {
    secret-key-files = ["/var/secrets/cache-priv-key.pem"];
  };

  services.nix-serve = {
    package = pkgs.nix-serve-ng;
    enable = true;
    bindAddress = "127.0.0.1";
    secretKeyFile = "/var/secrets/cache-priv-key.pem";
  };
}
