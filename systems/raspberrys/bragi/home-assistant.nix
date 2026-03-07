{
  config,
  lib,
  sensitive,
  ...
}: {
  services = {
    home-assistant = {
      enable = true;
      config = {
        http = {
          server_host = lib.mkForce ["127.0.0.1"];
          use_x_forwarded_for = true;
          trusted_proxies = ["127.0.0.1"];
        };
        mobile_app = {};
      };
      configWritable = false; # TODO: just to play around

      extraComponents = [
        "default_config"
        # Components required to complete the onboarding
        "analytics"
        "google_translate"
        "met"
        "radio_browser"
        "shopping_list"
        # Recommended for fast zlib compression
        # https://www.home-assistant.io/integrations/isal
        "isal"
        # extra
        "esphome"
        "shelly"
        "mobile_app"
      ];
    };
    nginx = {
      virtualHosts."ha.jonboh.dev" = {
        listen = [
          {
            port = 80;
            addr = sensitive.network.ip.bragi.viae;
            ssl = false;
          }
          {
            port = 443;
            addr = sensitive.network.ip.bragi.viae;
            ssl = true;
          }
          {
            port = 80;
            addr = sensitive.network.ip.bragi.lab;
            ssl = false;
          }
          {
            port = 443;
            addr = sensitive.network.ip.bragi.lab;
            ssl = true;
          }
        ];
        forceSSL = true;
        sslCertificate = "/var/lib/acme/jonboh.dev/fullchain.pem";
        sslCertificateKey = "/var/lib/acme/jonboh.dev/key.pem";
        extraConfig = ''
          proxy_buffering off;
        '';
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.home-assistant.config.http.server_port}";
          proxyWebsockets = true;
        };
      };
    };
  };
}
