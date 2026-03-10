{
  config,
  lib,
  sensitive,
  ...
}: let
  smokeAlarmConfig = {
    notificationData = {
      sticky = true;
      persistent = true;
      priority = "max";
      importance = "max";
      ttl = 0;
      vibrationPattern = "100, 1000, 100, 1000, 100, 1000, 100, 1000, 100, 1000, 100, 1000, 100";
      visibility = "public";
    };
    repeatConditions = [
      {
        condition = "state";
        entity_id = "input_boolean.smoke_alarm_acknowledged";
        state = "off";
      }
    ];
    repeatTriggers = [
      {
        platform = "time_pattern";
        seconds = "/15";
      }
    ];
    clearAcknowledgement = {
      service = "input_boolean.turn_off";
      target = {
        entity_id = "input_boolean.smoke_alarm_acknowledged";
      };
    };
  };

  mkSmokeNotificationAction = {
    title,
    message,
    channel ? "SmokeAlarm",
    extraData ? {},
  }: {
    service = "notify.mobile_app_pixel_8";
    data = {
      inherit message title;
      data = smokeAlarmConfig.notificationData // {inherit channel;} // extraData;
    };
  };

  mkRepeatingAlarmAutomation = {
    alias,
    description,
    triggerEntity,
    triggerCondition,
    actions,
  }: {
    inherit alias description;
    mode = "restart";
    trigger =
      [
        {
          platform = "state";
          entity_id = triggerEntity;
          to = "on";
        }
      ]
      ++ smokeAlarmConfig.repeatTriggers;
    condition = [triggerCondition] ++ smokeAlarmConfig.repeatConditions;
    action = actions;
  };

  mkClearAcknowledgementAutomation = {
    alias,
    description,
    triggerEntity,
  }: {
    inherit alias description;
    mode = "single";
    trigger = [
      {
        platform = "state";
        entity_id = triggerEntity;
        to = "on";
      }
    ];
    condition = [];
    action = [smokeAlarmConfig.clearAcknowledgement];
  };

  mkStandardSmokeNotifications = {
    place,
    debugPrefix ? "",
  }: [
    # TTS Notification
    (mkSmokeNotificationAction {
      title = "${debugPrefix}TTS: SMOKE on ${place}!!";
      message = "TTS";
      extraData = {
        media_stream = "alarm_stream_max";
        tts_text = "Fire on ${place}";
      };
    })
    # Regular Notification
    (mkSmokeNotificationAction {
      title = "${debugPrefix}SMOKE on ${place}!!";
      message = "Smoke on ${place}!!";
      channel =
        if debugPrefix != ""
        then "SmokeAlarm_${place}_Debug"
        else "SmokeAlarm_${place}";
    })
  ];

  # Function to create a complete smoke alarm system (repeating + clear acknowledgement)
  mkSmokeAlarmSystem = {
    place,
    triggerEntity,
    debugPrefix ? "",
  }: let
    systemName =
      if debugPrefix != ""
      then "Debug Notification for ${place}"
      else "Smoke Alert for ${place}";
  in [
    (mkRepeatingAlarmAutomation {
      alias = "${systemName} - Repeating";
      description = "Send ${systemName} alerts every 15 seconds until acknowledged";
      inherit triggerEntity;
      triggerCondition = {
        condition = "state";
        entity_id = triggerEntity;
        state = "on";
      };
      actions = mkStandardSmokeNotifications {inherit place debugPrefix;};
    })
    (mkClearAcknowledgementAutomation {
      alias = "Clear Smoke Alarm Acknowledgement for ${systemName}";
      description = "Clear acknowledgement when ${systemName} is activated";
      inherit triggerEntity;
    })
  ];
in {
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

        # Input boolean entities
        input_boolean = {
          smoke_alarm_acknowledged = {
            name = "Smoke Alarm Acknowledged";
            initial = false;
          };
          remove_smokealarm_channel = {
            name = "Remove Smoke Alarm Channel";
            initial = false;
          };
          debug_lab_notification_button = {
            name = "Debug Lab Notification Button";
            initial = false;
          };
          debug_kitchen_notification_button = {
            name = "Debug Kitchen Notification Button";
            initial = false;
          };
        };

        automation =
          # Real smoke detector system
          (mkSmokeAlarmSystem {
            place = "lab";
            triggerEntity = "binary_sensor.smoke_lab_smoke";
          })
          ++ (mkSmokeAlarmSystem {
            place = "kitchen";
            triggerEntity = "binary_sensor.smoke_kitchen_smoke";
          })
          ++
          # Manual trigger
          (mkSmokeAlarmSystem {
            place = "kitchen";
            triggerEntity = "input_boolean.debug_kitchen_notification_button";
            debugPrefix = "Debug: ";
          })
          ++ (mkSmokeAlarmSystem {
            place = "lab";
            triggerEntity = "input_boolean.debug_lab_notification_button";
            debugPrefix = "Debug: ";
          })
          ++
          # Additional utility automations
          [
            {
              alias = "Clear SmokeAlarm Channel";
              mode = "single";
              trigger = [
                {
                  platform = "state";
                  entity_id = "input_boolean.remove_smokealarm_channel";
                  from = "off";
                  to = "on";
                }
              ];
              condition = [];
              action = [
                {
                  service = "notify.mobile_app_pixel_8";
                  data = {
                    message = "remove_channel";
                    data = {
                      channel = "SmokeAlarm"; # Name of the channel you wish to remove
                    };
                  };
                }
              ];
            }
          ];
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
