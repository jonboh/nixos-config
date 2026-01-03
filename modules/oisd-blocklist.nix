{
  config,
  pkgs,
  lib,
  ...
}: let
  oisdEnabled = config.network.charon.dns.oisd.enable or false;
  oisdDir = "/var/oisd";
  oisdFile = "${oisdDir}/domainswild";
in {
  options.jonboh.configure.oisdDnsBlocklist.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable fetching of oisd Block List";
  };

  config = lib.mkIf oisdEnabled {
    users.users.oisd = {
      isSystemUser = true;
      description = "System user for fetching oisd Block List";
      group = "oisd";
      home = "/var/oisd";
      shell = "/sbin/nologin";
    };
    users.groups.oisd = {};

    systemd.services.fetchOisd = {
      description = "Fetch oisd Block List";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.curl}/bin/curl -o ${oisdFile} https://nsfw.oisd.nl/domainswild";
        User = "oisd";
        Group = "oisd";
      };
    };

    systemd.timers.fetchOisdTimer = {
      description = "Timer to fetch oisd Block List periodically";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };

    system.activationScripts.ensureOisdDir = ''
      mkdir -p ${oisdDir}
      chown oisd:oisd ${oisdDir}
      touch ${oisdFile}
      chown oisd:oisd ${oisdFile}
    '';
  };
}
