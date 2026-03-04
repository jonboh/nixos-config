{
  sensitive,
  lib,
  ...
}: let
  listen_ip_viae = sensitive.network.ip.bragi.viae;
  listen_ip_lan = sensitive.network.ip.bragi.lab;
in {
  services.home-assistant = {
    enable = true;
    config.http.server_host = lib.mkForce [listen_ip_viae listen_ip_lan];
    configWritable = true; # TODO: just to play around
  };
}
