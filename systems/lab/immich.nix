{
  pkgs,
  config,
  ...
}: {
  services.immich = {
    enable = true;
    package = pkgs.immich;
    host = "127.0.0.1";
    accelerationDevices = null; # `null` will give access to all devices.
  };
  services.nginx.virtualHosts."immich.jonboh.dev" = {
    forceSSL = true;
    sslCertificate = "/var/lib/acme/jonboh.dev/fullchain.pem";
    sslCertificateKey = "/var/lib/acme/jonboh.dev/key.pem";
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.immich.port}";
      proxyWebsockets = true;
      recommendedProxySettings = true;
      extraConfig = ''
        client_max_body_size 50000M;
        proxy_read_timeout   600s;
        proxy_send_timeout   600s;
        send_timeout         600s;
      '';
    };
  };
}
