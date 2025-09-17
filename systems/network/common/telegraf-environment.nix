{
  pkgs,
  lib,
  config,
  ...
}: {
  systemd.services.telegraf = {
    after = ["derived-secrets.service"];
    wants = ["derived-secrets.service"];
    serviceConfig = {
      # Keep retrying if failed to start
      StartLimitBurst = 10000;
      Restart = lib.mkForce "always";
      RestartSec = "5s";
    };
  };

  systemd.services.derived-secrets = {
    description = "Create a dotenv file for Telegraf to consume";
    wantedBy = ["multi-user.target" "telegraf.service"];
    path = [pkgs.coreutils];
    script = ''
      set -e
      token=$(cat ${config.sops.secrets.influxdb-token.path})
      mkdir -p /run/secrets_derived/
      echo "INFLUXDB_TOKEN=$token" > /run/secrets_derived/influxdb.env
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  sops.secrets.influxdb-token = {
    restartUnits = ["derived-secrets.service" "telegraf.service"];
  };
}
