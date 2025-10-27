{
  self,
  pkgs,
  config,
  lib,
  modulesPath,
  sensitive,
  ...
}: {
  imports = [
    ../common/configuration.nix
    ../common/hardware-metrics.nix
    ../common/hardware-rpi4.nix
    ../common/sops.nix
    ./daily-backup.nix
    ./network.nix
    ./builder.nix
    ./sops.nix
    ./telegraf-environment.nix
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
  ];
  networking.hostName = "tars";

  security.acme = {
    acceptTerms = true;
    defaults.email = "jon.bosque.hernando@gmail.com";
    defaults.enableDebugLogs = true;
    certs."jonboh.dev" = {
      domain = "*.jonboh.dev";
      dnsProvider = "rfc2136";
      environmentFile = config.sops.secrets.certs-secrets.path;
      dnsPropagationCheck = false;
      server = "https://acme-staging-v02.api.letsencrypt.org/directory"; # NOTE: use this for debugging
      validMinDays = 90;
    };
  };
  users.users.nginx.extraGroups = ["acme"];

  services = {
    syncthing = {
      enable = true;
      user = "jonboh";
      dataDir = "/home/jonboh/.syncthingDataDir";
      configDir = "/home/jonboh/.config/syncthing";
      openDefaultPorts = true;
      overrideDevices = true;
      overrideFolders = true;
      settings = {
        devices = {
          "workstation" = {
            id = sensitive.ids.syncthing-workstation;
          };
          "phone" = {
            id = sensitive.ids.syncthing-phone;
          };
          "wsl" = {
            id = sensitive.ids.syncthing-wsl;
          };
          "laptop" = {
            id = sensitive.ids.syncthing-laptop;
          };
          "lab" = {
            id = sensitive.ids.syncthing-lab;
          };
        };
        folders = {
          "newsboat-state" = {
            path = "/mnt/storage/.local/share/newsboat";
            devices = [
              "workstation"
              "laptop"
            ];
          };
          "devel" = {
            path = "/mnt/storage/devel";
            devices = ["workstation"];
            type = "sendreceive";
          };
          "vault" = {
            path = "/mnt/storage/vault";
            devices = ["workstation" "laptop" "phone" "wsl" "lab"];
            type = "sendreceive";
          };

          "doc" = {
            path = "/mnt/storage/doc";
            devices = ["workstation"];
            type = "receiveonly";
          };
          "books" = {
            path = "/mnt/storage/books";
            devices = ["workstation" "laptop" "phone" "lab"];
            type = "receiveonly";
          };
          "phone_camera" = {
            path = "/mnt/storage/phone_camera";
            devices = ["phone" "workstation"];
            type = "receiveonly";
            ignoreDelete = true;
          };
          "phone_whatsapp" = {
            path = "/mnt/storage/phone_whatsapp";
            devices = ["phone" "workstation"];
            type = "receiveonly";
            ignoreDelete = true;
          };
          "aegis_vault_backups" = {
            path = "/mnt/storage/aegis_vault_backups";
            devices = ["phone"];
            type = "receiveonly";
          };
        };
      };
    };
    samba = {
      enable = true;
      nmbd.enable = false; # disable NETBIOS
      settings = {
        global = {
          "guest account" = "nobody";
          "smb ports" = "${toString sensitive.network.port.tcp.tars.samba}";
          "hosts allow" = "${sensitive.network.vlan-range "lab"} 127.0.0.1 localhost";
          "hosts deny" = "0.0.0.0/0";
        };
        writable_file_exchange = {
          path = "/mnt/storage/file_exchange";
          "read only" = false;
          writable = true;
          browseable = true;
          public = false;
          comment = "Writable File Exchange";
          "valid users" = "jonboh";
        };
      };
    };
    influxdb2 = {
      enable = true;
      provision = {
        enable = true;
        initialSetup = {
          bucket = "sensors";
          organization = "jonboh";
          tokenFile = config.sops.secrets.influxdb-token.path;
          passwordFile = config.sops.secrets.influxdb-password.path;
        };
      };
      settings = {
        http-bind-address = "127.0.0.1:8086";
      };
    };
    telegraf = {
      extraConfig = {
        inputs = {
          mqtt_consumer = {
            servers = ["tcp://influx.jonboh.dev:${toString sensitive.network.port.tcp.tars.mqtt}"];
            topics = [
              "iaq-lab/sensor/+/state"
              "iaq-bedroom/sensor/+/state"
              "iaq-outside/sensor/+/state"
              "iaq-livingroom/sensor/+/state"
            ];
            topic_parsing = [
              {
                topic = "iaq-bedroom/sensor/+/state";
                measurement = "_/_/measurement/_";
                tags = "iaq-board/_/_/_";
              }
              {
                topic = "iaq-lab/sensor/+/state";
                measurement = "_/_/measurement/_";
                tags = "iaq-board/_/_/_";
              }
              {
                topic = "iaq-outside/sensor/+/state";
                measurement = "_/_/measurement/_";
                tags = "iaq-board/_/_/_";
              }
              {
                topic = "iaq-livingroom/sensor/+/state";
                measurement = "_/_/measurement/_";
                tags = "iaq-board/_/_/_";
              }
            ];
            username = "influx";
            password = "$INFLUX_MQTT_PASSWORD";
            data_format = "value";
            data_type = "float";
          };
        };
      };
    };
    mosquitto = {
      enable = true;
      logType = ["error" "warning" "information" "notice"];
      # logType = ["all"];
      listeners = [
        {
          port = sensitive.network.port.tcp.tars.mqtt;
          users = {
            iaq-lab = {
              acl = [
                "write iaq-lab/#"
              ];
              passwordFile = "/run/secrets/iaq-lab-mqtt-password";
            };
            iaq-bedroom = {
              acl = [
                "write iaq-bedroom/#"
              ];
              passwordFile = "/run/secrets/iaq-bedroom-mqtt-password";
            };
            iaq-outside = {
              acl = [
                "write iaq-outside/#"
                "write iaq-livingroom/#"
              ];
              passwordFile = "/run/secrets/iaq-outside-mqtt-password";
            };
            influx = {
              acl = [
                "read iaq-lab/#"
                "read iaq-bedroom/#"
                "read iaq-outside/#"
                "read iaq-livingroom/#"
              ];
              passwordFile = "/run/secrets/influx-mqtt-password";
            };
          };
        }
      ];
    };
    radicale = {
      enable = true;
      settings = {
        server = {
          hosts = ["127.0.0.1:5232"];
          ssl = false;
        };
        auth = {
          type = "htpasswd";
          htpasswd_filename = "/run/secrets/radicale-user";
          htpasswd_encryption = "bcrypt";
        };
        storage.filesystem_folder = "/mnt/storage/radicale/collections";
      };
      rights = {
        root = {
          # Allow reading root collection for authenticated users
          user = ".+";
          collection = "";
          permissions = "R";
        };

        principal = {
          # Allow reading and writing principal collection (same as username)
          user = ".+";
          collection = "{user}";
          permissions = "RW";
        };

        calendars = {
          # Allow reading and writing calendars and address books that are direct
          # children of the principal collection
          user = ".+";
          collection = "{user}/[^/]+";
          permissions = "rw";
        };
        optimitive_calendar = {
          # Allow anonymous (thunderbird) writing to into the work calendar
          user = ".*";
          collection = "jonboh/optimitive-calendar";
          permissions = "rw";
        };
      };
    };

    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedZstdSettings = true;
      recommendedBrotliSettings = true;
      # recommendedProxySettings = true; # NOTE: breaks requests with 400 Bad Request
      recommendedOptimisation = true;
      recommendedTlsSettings = true;
      virtualHosts."influx.jonboh.dev" = {
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
        # https://github.com/influxdata/influxdb/issues/15721#issuecomment-3148425970
        locations."/" = {
          proxyPass = "http://${config.services.influxdb2.settings.http-bind-address}";
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
      };
      virtualHosts."atuin.jonboh.dev" = {
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
          proxyPass = "http://${config.services.atuin.host}:${toString config.services.atuin.port}";
          recommendedProxySettings = true;
        };
      };
      virtualHosts."grafana.jonboh.dev" = {
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
          proxyPass = "http://${config.services.grafana.settings.server.http_addr}:${toString config.services.grafana.settings.server.http_port}";
          recommendedProxySettings = true;
        };
      };
      virtualHosts."firefox.jonboh.dev" = {
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
          proxyPass = "http://${config.services.firefox-syncserver.settings.host}:${toString config.services.firefox-syncserver.settings.port}";
          recommendedProxySettings = true;
        };
      };
      virtualHosts."radicale.jonboh.dev" = {
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
          proxyPass = "http://${builtins.elemAt config.services.radicale.settings.server.hosts 0}";
          recommendedProxySettings = true;
        };
      };
      virtualHosts."loki.jonboh.dev" = {
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
          recommendedProxySettings = true;
        };
      };
    };
    grafana = {
      enable = true;
      declarativePlugins = [pkgs.logs-drilldown];
      provision = {
        enable = true;
        dashboards = {
          settings = {
            apiVersion = 1;
            providers = [
              {
                name = "NixStoreDashboards";
                type = "file";
                disableDeletion = true;
                updateIntervalSeconds = 10;
                allowUiUpdates = false;
                options = {
                  path = ./dashboards;
                  foldersFromFilesStructure = true;
                };
              }
            ];
          };
        };
        datasources = {
          settings = {
            apiVersion = 1;
            datasources = [
              {
                name = "InfluxDB";
                type = "influxdb";
                url = "https://influx.jonboh.dev/";
                jsonData = {
                  version = "Flux";
                  organization = "jonboh";
                  defaultBucket = "sensors";
                  tlsSkipVerify = true;
                };
                secureJsonData = {
                  token = "$INFLUXDB_TOKEN";
                };
              }
              {
                name = "loki";
                type = "loki";
                url = "https://loki.jonboh.dev";
              }
            ];
          };
        };
      };
      settings = {
        server = {
          domain = "jonboh.dev";
          http_addr = "127.0.0.1";
          http_port = 3000;
          root_url = "https://grafana.jonboh.dev";
        };
        dashboards.default_home_dashboard_path = "${./dashboards/hardware.json}";
      };
    };

    loki = {
      enable = true;
      configuration = {
        auth_enabled = false;

        server = {
          http_listen_port = 3100;
        };

        limits_config = {
          ingestion_rate_mb = 32;
          ingestion_burst_size_mb = 32;
        };

        common = {
          ring = {
            instance_addr = "127.0.0.1";
            kvstore = {
              store = "inmemory";
            };
          };
          replication_factor = 1;
          path_prefix = "/tmp/loki";
        };

        schema_config = {
          configs = [
            {
              from = "2020-05-15";
              store = "tsdb";
              object_store = "filesystem";
              schema = "v13";
              index = {
                prefix = "index_";
                period = "24h";
              };
            }
          ];
        };
        storage_config = {
          filesystem = {
            directory = "/tmp/loki/chunks";
          };
        };
      };
    };
    atuin = {
      enable = true;
      host = "127.0.0.1";
      port = 8888;
      path = "/atuin/";
      openRegistration = true;
      database.createLocally = true;
    };
    firefox-syncserver = {
      enable = true;
      logLevel = "debug";
      database = {
        createLocally = true;
      };
      singleNode = {
        enable = true;
        url = "https://firefox.jonboh.dev";
        capacity = 4;
        hostname = "127.0.0.1";
      };
      secrets = config.sops.secrets.firefox-syncserver.path;
      settings = {
        host = "127.0.0.1";
        port = 5000;
        syncstorage = {
          enabled = true;
          enable_quota = 0;
          limits.max_total_records = 1666; # See issues #298/#333
        };
      };
    };
    mysql.package = pkgs.mariadb;
  };
  systemd.services.grafana.serviceConfig.EnvironmentFile = "/run/secrets_derived/influxdb.env";
  systemd.services.influxdb2.serviceConfig.ExecStart = lib.mkForce "${pkgs.influxdb2}/bin/influxd --bolt-path /mnt/storage/influxdb2/influxd.bolt --engine-path /mnt/storage/influxdb2/engine --sqlite-path /mnt/storage/influxdb2/influxd.sqlite";
  systemd.services.influxdb2.preStart = lib.mkForce "";

  users = {
    users.influxdb2.extraGroups = ["influx-secrets"];
    users.grafana.extraGroups = ["influx-secrets"];
    users.git = {
      isNormalUser = true;
      createHome = false; # provisioned with a symlink to /mnt/storage/git-server on activationScripts
      hashedPassword = null;
      openssh.authorizedKeys.keys = [
        sensitive.keys.ssh.workstation
        sensitive.keys.ssh.lab
        sensitive.keys.ssh.phone
        sensitive.keys.ssh.wsl
        sensitive.keys.ssh.laptop
      ];
    };
  };

  # set up smb user
  system.activationScripts = {
    smbuser = ''
      cat /run/secrets/smb-password /run/secrets/smb-password | ${pkgs.samba}/bin/smbpasswd -a jonboh -s
    '';
    git-server-symlink = "test -L /home/git || (${pkgs.coreutils}/bin/ln -s /mnt/storage/git-server /home/git && chown -h git:users /home/git)";
  };

  fileSystems = {
    "/mnt/storage" = {
      device = "/dev/disk/by-label/sync-drive";
      fsType = "ext4";
    };
  };

  environment.systemPackages = with pkgs; [
    influxdb2-cli
    htop
    bindfs
    wireguard-tools
  ];

  zramSwap = {
    enable = true;
    priority = 5;
  };
  swapDevices = [
    {
      size = 4 * 1024;
      priority = 10;
      device = "/var/lib/swapfile";
      randomEncryption.enable = true;
    }
  ];

  boot.kernel.sysctl."fs.inotify.max_user_watches" = 524288; # increase inotify limit for syncthing archive share
  system.stateVersion = "23.11";
}
