{
  self,
  pkgs,
  config,
  lib,
  modulesPath,
  sensitive,
  ...
}: let
  nginxPort = 80;
  nginxPortSSL = 443;
  sambaPort = 445; # samba (without NETBIOS)
  mqttPort = 1883;
  radicalePort = 5232;
  grafanaPort = 3000;
  lokiPort = 3100;
  influxdbPort = 8086;
  atuinPort = 8888;
  syncserverPort = 5000;
in {
  imports = [
    ../common/configuration.nix
    ../common/hardware-metrics.nix
    ../common/hardware-rpi4.nix
    ../common/sops.nix
    ./daily-backup.nix
    ./builder.nix
    ./sops.nix
    ./telegraf-environment.nix
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
  ];
  networking.hostName = "tars";

  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [
        nginxPort
        nginxPortSSL
        sambaPort
        mqttPort
        radicalePort # TODO: mask behind nginx
        lokiPort # TODO: mask behind nginx
      ];
    };
    interfaces = {
      end0 = {
        useDHCP = true;
        ipv4.addresses = [
          {
            address = sensitive.network.ip.tars;
            prefixLength = 24;
          }
        ];
      };
    };
    timeServers = [(sensitive.network.ntp-server "lab")];
    extraHosts = ''
      ${sensitive.network.ip.tars} tars.lan
    ''; # actually needed to make samba work without timeouts due to missing DNS/Gateway on tars
    defaultGateway = sensitive.network.ip.charon.lab;
  };

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
          "zathura-state" = {
            path = "/mnt/storage/.local/share/zathura";
            devices = [
              "workstation"
              "laptop"
            ];
            type = "sendreceive";
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

          "archive" = {
            path = "/mnt/storage/archive";
            devices = ["workstation"];
            type = "receiveonly";
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
          "smb ports" = "${toString sambaPort}";
          "hosts allow" = "${sensitive.network.vlan-range "lab"}/24 ${sensitive.network.vlan-range "rift"}/24 127.0.0.1 localhost";
          "hosts deny" = "0.0.0.0/0";
        };
        media = {
          path = "/mnt/storage/shared_media";
          "read only" = true;
          browseable = true;
          public = true;
          comment = "Shared Media";
        };
        writable_media = {
          path = "/mnt/storage/shared_media";
          "read only" = false;
          writable = true;
          browseable = true;
          public = false;
          comment = "Writable Shared Media";
          "valid users" = "jonboh";
        };
        writable_file_exchange = {
          path = "/mnt/file_exchange";
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
        http-bind-address = "127.0.0.1:${toString influxdbPort}";
      };
    };
    telegraf = {
      extraConfig = {
        inputs = {
          mqtt_consumer = {
            servers = ["tcp://tars.lan:${toString mqttPort}"];
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
          port = mqttPort;
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
          hosts = ["0.0.0.0:${toString radicalePort}"];
          ssl = true;
          certificate = "/run/secrets/radicale-server-cert";
          key = "/run/secrets/radicale-server-key";
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
      virtualHosts."tars.lan" = {
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
        sslCertificate = self.inputs.nixos-config-sensitive + /certificates/tars-selfsigned.crt;
        sslCertificateKey = config.sops.secrets.tars-cert-key.path;
        # https://github.com/influxdata/influxdb/issues/15721#issuecomment-3148425970
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString influxdbPort}";
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
        locations."/grafana/" = {
          proxyPass = "http://127.0.0.1:${toString grafanaPort}";
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
        locations."/atuin/" = {
          proxyPass = "http://127.0.0.1:${toString atuinPort}";
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
      };
      virtualHosts."firefox.tars.lan" = {
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
        sslCertificate = self.inputs.nixos-config-sensitive + /certificates/tars-selfsigned.crt;
        sslCertificateKey = config.sops.secrets.tars-cert-key.path;
        # https://github.com/influxdata/influxdb/issues/15721#issuecomment-3148425970
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString syncserverPort}";
          recommendedProxySettings = true;
        };
      };
      # TODO: use radicale_client_key/cert.pem
      # TODO: unify all services in nginx reverse-proxy
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
                url = "https://tars.lan/";
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
                url = "http://localhost:3100";
              }
            ];
          };
        };
      };
      settings = {
        server = {
          domain = "tars.lan";
          http_addr = "127.0.0.1";
          http_port = grafanaPort;
          root_url = "https://tars.lan/grafana/";
          serve_from_sub_path = true;
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
            instance_addr = "0.0.0.0";
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
      path = "/atuin/";
      openRegistration = true;
      database.createLocally = true;
    };
    firefox-syncserver = {
      # NOTE: probably due to my cert being a self-signed one, I have to first try
      # to access https://firefox.tars.lan, accept the risk, and then sync works!
      enable = true;
      logLevel = "debug";
      database = {
        createLocally = true;
      };
      singleNode = {
        enable = true;
        url = "https://firefox.tars.lan";
        capacity = 4;
        hostname = "127.0.0.1";
      };
      secrets = config.sops.secrets.firefox-syncserver.path;
      settings = {
        host = "127.0.0.1";
        port = syncserverPort;
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
  security.pki = {
    certificateFiles = [(self.inputs.nixos-config-sensitive + /certificates/tars-selfsigned.crt)];
  };

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
      device = "/dev/disk/by-label/sync_drive";
      fsType = "ext4";
    };
  };

  environment.systemPackages = with pkgs; [
    influxdb2-cli
    htop
    bindfs
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
