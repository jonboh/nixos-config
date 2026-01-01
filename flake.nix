{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-bragi.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-tars.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-forge.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-brick.url = "github:nixos/nixpkgs/nixos-25.11";
    # prev nixpkgs releases
    nixpkgs-2505.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-2411.url = "github:nixos/nixpkgs/nixos-24.11";
    # app pins
    nixpkgs-navidrome.url = "github:nixos/nixpkgs?ref=ae814fd3904b621d8ab97418f1d0f2eb0d3716f4";
    nixpkgs-immich.url = "github:nixos/nixpkgs?ref=ae814fd3904b621d8ab97418f1d0f2eb0d3716f4";
    # follow `main` branch of this repository, considered being stable
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";
    raspberry-pi-nix.url = "github:nix-community/raspberry-pi-nix";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim-config.url = "git+ssh://git@tars.lan/home/git/nixvim-config.git?ref=main";
    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-ld = {
      url = "github:nix-community/nix-ld";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-sbc = {
      url = "github:nakato/nixos-sbc/main";
    };
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    nixpkgs-wsl.url = "github:nixos/nixpkgs/nixos-25.11";
    home-manager-wsl = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    raspi-fancontrol = {
      url = "github:jonboh/raspi-fancontrol";
    };
    nixos-config-sensitive = {
      # Extra values for configuration, mostly network specific
      # url = "/home/jonboh/.flakes/nixos-config-sensitive";
      url = "git+ssh://git@tars.lan/home/git/nixos-config-sensitive.git?ref=main";
      flake = false;
    };
    nixos-config-extra-private = {
      # Extra configuration files, mostly programs with big config files that
      # sometimes mix configuration and sensitive or identifiable info.
      url = "git+ssh://git@tars.lan/home/git/nixos-config-extra-private.git?ref=main";
      flake = false;
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://nixos-raspberrypi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
    allow-import-from-derivation = true; # suricata build in hydra needs this. Otherwise, fails on `nix flake check`
  };

  outputs = {
    self,
    nixos-sbc,
    nixos-wsl,
    ...
  } @ inputs: let
    navidrome-pin-overlay = final: prev: {
      navidrome = inputs.nixpkgs-navidrome.legacyPackages.x86_64-linux.navidrome;
    };
    immich-pin-overlay = final: prev: {
      immich = inputs.nixpkgs-immich.legacyPackages.x86_64-linux.immich;
    };
    unstable-overlay = system: final: prev: {
      unstable = import inputs.nixpkgs-unstable {
        inherit system;
        config = prev.config;
      };
    };
    stable-2505-overlay = system: final: prev: {
      stable-2505 = import inputs.nixpkgs-2505 {
        inherit system;
        config = prev.config;
      };
    };
    pkgs = import inputs.nixpkgs rec {
      system = "x86_64-linux";
      config = {
        allowUnfree = true;
      };
      overlays = [
        immich-pin-overlay
        (unstable-overlay system)
        (stable-2505-overlay system)
        (final: prev: {shai = pkgs.callPackage ./packages/shai.nix {};})
        (final: prev: {
          xdg-desktop-portal-termfilechooser =
            pkgs.callPackage
            ./packages/xdg-desktop-portal-termfilechooser.nix {
              inherit pkgs;
            };
        })
        (final: prev: {
          nixvim = inputs.nixvim-config.packages.${prev.system}.nixvim-nightly-config;
        })
        (final: prev: {
          nixvim-light = inputs.nixvim-config.packages.${prev.system}.nixvim-light-config;
        })
        (final: prev: {
          openfortivpn-webview-qt =
            pkgs.callPackage ./packages/openfortivpn-webview-qt.nix {};
        })
        (final: prev: {
          girara = prev.girara.overrideAttrs rec {
            version = "0.4.5";

            src = pkgs.fetchFromGitHub {
              owner = "pwmt";
              repo = "girara";
              tag = version;
              hash = "sha256-XjRmGgljlkvxwcbPmA9ZFAPAjbClSQDdmQU/GFeLLxI=";
            };
          };
          zathuraPkgs = rec {
            zathura_core = prev.zathuraPkgs.zathura_core.overrideAttrs (o: {
              version = "0.5.11-jonboh-dev";
              src = pkgs.fetchFromGitHub {
                owner = "jonboh";
                repo = "zathura";
                rev = "3ab2d4336ca097d29cd20d5c6a0ba94d2df75e05";
                hash = "sha256-sxmiQLHCaizsH5g9pEydUOdd4AP8ajhqihQDPOzSKHk=";
              };
              patches = [];
            });

            zathuraWrapper = prev.zathuraPkgs.zathuraWrapper.override {
              inherit zathura_core;
            };
          };
          zathura = final.zathuraPkgs.zathuraWrapper;
        })
        (final: prev: {
          libfprint = prev.libfprint.overrideAttrs (oldAttrs: {
            version = "git";
            src = final.fetchFromGitHub {
              owner = "ericlinagora";
              repo = "libfprint-CS9711";
              rev = "c242a40fcc51aec5b57d877bdf3edfe8cb4883fd";
              sha256 = "sha256-WFq8sNitwhOOS3eO8V35EMs+FA73pbILRP0JoW/UR80=";
            };
            nativeBuildInputs =
              oldAttrs.nativeBuildInputs
              ++ [
                final.opencv
                final.cmake
                final.doctest
                final.nss
              ];
          });
        })
        (final: prev: {
          fprintd = pkgs.callPackage ./packages/fprintd-1.94.4 {};
        })
        ccache-overlay
      ];
    };
    nixpkgs-charon = inputs.nixos-sbc.inputs.nixpkgs;
    sun4i-drm-fix-overlay = final: super: {
      # NOTE: this solves Module sun4i-drm not found in directory. see https://github.com/NixOS/nixpkgs/issues/154163
      makeModulesClosure = x:
        super.makeModulesClosure (x // {allowMissing = true;});
    };
    lib = inputs.nixpkgs.lib;
    ccache-overlay = self: super: {
      ccacheWrapper = super.ccacheWrapper.override {
        extraConfig = ''
          export CCACHE_COMPRESS=1
          export CCACHE_DIR="/var/cache/ccache"
          export CCACHE_UMASK=007
          export CCACHE_MAXSIZE="15G"
          # Ignore -frandom-seed: https://github.com/NixOS/nixpkgs/issues/109033
          export CCACHE_SLOPPINESS=random_seed
          # https://discourse.nixos.org/t/ccache-does-not-work-with-c-c-compiles-homeless-shelter-error-message/19154/2
          export HOME="$CCACHE_DIR"
          if [ ! -d "$CCACHE_DIR" ]; then
            echo "====="
            echo "Directory '$CCACHE_DIR' does not exist"
            echo "Please create it with:"
            echo "  sudo mkdir -m0770 '$CCACHE_DIR'"
            echo "  sudo chown root:nixbld '$CCACHE_DIR'"
            echo "====="
            exit 1
          fi
          if [ ! -w "$CCACHE_DIR" ]; then
            echo "====="
            echo "Directory '$CCACHE_DIR' is not accessible for user $(whoami)"
            echo "Please verify its access permissions"
            echo "====="
            exit 1
          fi
        '';
      };
    };
  in rec {
    formatter.x86_64-linux =
      inputs.nixpkgs.legacyPackages.x86_64-linux.alejandra;

    devShells.x86_64-linux = {
      esp = pkgs.mkShell {
        name = "esp-devshell";
        packages = with pkgs; [
          esphome
          esptool
          mosquitto
          influxdb2-cli
        ];
      };
      terraform = pkgs.mkShell {
        name = "terraform-devshell";
        packages = with pkgs; [terraform];
      };
      rust = pkgs.mkShell {
        name = "rust-devshell";
        packages = with pkgs; [
          rustup
          openssl
          pkg-config
          cargo-deny
          cargo-edit
          cargo-expand
          cargo-nextest
          rust-analyzer
          bacon
          hyperfine
          samply
          pkg-config
          openssl
        ];
        shellHook = ''
          export PATH=/home/jonsboh/.cargo/bin:$PATH
        '';
      };
      julia = let
        julia-pkg = pkgs.julia_111-bin;
      in
        pkgs.mkShell {
          # use `]pkg add <package>` to install packages
          packages = [julia-pkg];
          name = "julia-devshell";
          shellHook = ''
            export LD_LIBRARY_PATH="${julia-pkg}/lib":$LD_LIBRARY_PATH
            export LD_LIBRARY_PATH="/run/opengl-driver/lib:/run/opengl-driver-32/lib":$LD_LIBRARY_PATH
          '';
        };
    };

    nixosConfigurations = let
      sensitive = import inputs.nixos-config-sensitive;
      # used to build forge with and without klipper-firmware
      mkForgeSystem = extraModules: let
        nixpkgs = inputs.nixpkgs-forge;
      in
        nixpkgs.lib.nixosSystem rec {
          system = "aarch64-linux";
          specialArgs = {
            inherit self;
            inherit sensitive;
          };
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              sun4i-drm-fix-overlay
              ccache-overlay
            ];
          };
          modules =
            [
              inputs.sops.nixosModules.sops
              ./modules
              ./systems/raspberrys/forge/configuration.nix
            ]
            ++ extraModules;
        };
    in {
      "lab" = lib.nixosSystem {
        system = "x86_64-linux";
        inherit pkgs;
        specialArgs = {
          inherit self;
          inherit sensitive;
        };
        modules = [
          inputs.sops.nixosModules.sops
          inputs.nix-index-database.nixosModules.nix-index
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.jonboh = {
              imports = [./home-manager/lab.nix];
            };
            home-manager.extraSpecialArgs = {inherit self;};
          }
          ./modules
          ./systems/lab/configuration.nix
        ];
      };
      "workstation" = lib.nixosSystem {
        system = "x86_64-linux";
        inherit pkgs;
        specialArgs = {
          inherit self;
          inherit sensitive;
        };
        modules = [
          inputs.sops.nixosModules.sops
          inputs.nix-index-database.nixosModules.nix-index
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.jonboh = ./home-manager/workstation.nix;
            home-manager.extraSpecialArgs = {inherit self;};
          }
          ./modules
          ./systems/workstation/configuration.nix
        ];
      };

      "laptop" = lib.nixosSystem {
        system = "x86_64-linux";
        inherit pkgs;
        specialArgs = {
          inherit self;
          inherit sensitive;
        };
        modules = [
          inputs.sops.nixosModules.sops
          inputs.nix-index-database.nixosModules.nix-index
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.jonboh = {
              imports = [./home-manager/laptop.nix];
            };
            home-manager.extraSpecialArgs = {inherit self;};
          }
          ./modules
          ./systems/laptop/configuration.nix
        ];
      };

      "tars" = let
        nixpkgs = inputs.nixpkgs-tars;
      in
        nixpkgs.lib.nixosSystem rec {
          system = "aarch64-linux";
          specialArgs = {
            inherit self;
            inherit sensitive;
          };
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              sun4i-drm-fix-overlay
              ccache-overlay
              (unstable-overlay system)
              (final: prev: {
                grafanaPlugin = pkgs.callPackage (nixpkgs + "/pkgs/servers/monitoring/grafana/plugins/grafana-plugin.nix") {};
              })
            ];
          };
          modules = [
            inputs.sops.nixosModules.sops
            ./modules
            ./systems/raspberrys/tars/configuration.nix
          ];
        };
      "bragi" = let
        nixpkgs = inputs.nixpkgs-bragi;
      in
        nixpkgs.lib.nixosSystem rec {
          system = "aarch64-linux";
          specialArgs = {
            inherit self;
            inherit sensitive;
          };
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              # navidrome-pin-overlay
              sun4i-drm-fix-overlay
              ccache-overlay
              (unstable-overlay system)
            ];
          };
          modules = [
            inputs.sops.nixosModules.sops
            ./modules
            ./systems/raspberrys/bragi/configuration.nix
          ];
        };
      "forge" = mkForgeSystem [];
      "forge-klipper-firmware" = mkForgeSystem [
        {
          services.klipper = {
            package = lib.mkForce pkgs.klipper;
            firmwares.printer.enable = lib.mkForce true;
            firmwares.resonance.enable = lib.mkForce true;
          };
        }
      ];
      "brick" = inputs.nixpkgs-brick.lib.nixosSystem rec {
        system = "aarch64-linux";
        specialArgs = {
          inherit self;
          inherit sensitive;
        };
        pkgs = import inputs.nixpkgs-brick {
          inherit system;
          overlays = [
            ccache-overlay
            (final: prev: {
              rp-fancontrol = self.inputs.raspi-fancontrol.packages.aarch64-linux.default;
            })
          ];
        };
        modules = [
          inputs.sops.nixosModules.default
          inputs.raspberry-pi-nix.nixosModules.raspberry-pi
          inputs.raspberry-pi-nix.nixosModules.sd-image
          ./modules
          ./systems/raspberrys/brick/configuration.nix
        ];
      };
      "palantir" = inputs.nixos-raspberrypi.lib.nixosSystemFull rec {
        system = "aarch64-linux";
        specialArgs = {
          inherit self;
          inherit sensitive;
          nixos-raspberrypi = inputs.nixos-raspberrypi;
        };
        pkgs = import inputs.nixos-raspberrypi.inputs.nixpkgs {
          inherit system;
          overlays = [
            (final: prev: {
              rp-fancontrol = self.inputs.raspi-fancontrol.packages.aarch64-linux.default;
            })
            (final: prev: {
              gjs = prev.gjs.overrideAttrs (oldAttrs: {
                doCheck = false; # Disable tests that timeout on aarch64
              });
              sdl3 = prev.sdl3.overrideAttrs (oldAttrs: {
                doCheck = false; # Disable failing tests
              });
            })
          ];
        };
        modules = [
          {
            imports = with inputs.nixos-raspberrypi.nixosModules; [
              raspberry-pi-5.base
              raspberry-pi-5.page-size-16k
              raspberry-pi-5.display-vc4
              raspberry-pi-5.bluetooth
              sd-image
              # raspberry-pi-5.wifi
            ];
          }
          inputs.sops.nixosModules.default
          ./modules
          ./systems/raspberrys/palantir/configuration.nix
        ];
      };
      "sentinel" = inputs.nixos-raspberrypi.lib.nixosSystem rec {
        system = "aarch64-linux";
        specialArgs = {
          inherit self;
          inherit sensitive;
          nixos-raspberrypi = inputs.nixos-raspberrypi;
        };
        pkgs = import inputs.nixos-raspberrypi.inputs.nixpkgs {
          inherit system;
          overlays = [
            (final: prev: {
              rp-fancontrol = self.inputs.raspi-fancontrol.packages.aarch64-linux.default;
            })
            (final: prev: {
              valkey = prev.valkey.overrideAttrs (oldAttrs: {
                doCheck = false; # tests are flaky: https://github.com/NixOS/nixpkgs/issues/387010
              });
            })
          ];
        };
        modules = [
          {
            imports = with inputs.nixos-raspberrypi.nixosModules; [
              raspberry-pi-5.base
              raspberry-pi-5.page-size-16k
              raspberry-pi-5.display-vc4
              raspberry-pi-5.bluetooth
              sd-image
              # raspberry-pi-5.wifi
            ];
          }
          inputs.sops.nixosModules.default
          ./modules
          ./systems/raspberrys/sentinel/configuration.nix
        ];
      };
      "eva" = inputs.nixos-raspberrypi.lib.nixosSystemFull rec {
        system = "aarch64-linux";
        specialArgs = {
          inherit self;
          inherit sensitive;
          nixos-raspberrypi = inputs.nixos-raspberrypi;
        };
        pkgs = import inputs.nixos-raspberrypi.inputs.nixpkgs {
          inherit system;
          overlays = [
            (final: prev: {
              rp-fancontrol = self.inputs.raspi-fancontrol.packages.aarch64-linux.default;
            })
          ];
        };
        modules = [
          {
            imports = with inputs.nixos-raspberrypi.nixosModules; [
              raspberry-pi-5.base
              raspberry-pi-5.page-size-16k
              raspberry-pi-5.display-vc4
              raspberry-pi-5.bluetooth
              sd-image
              # raspberry-pi-5.wifi
            ];
          }
          inputs.sops.nixosModules.default
          ./modules
          ./systems/raspberrys/eva/configuration.nix
        ];
      };
      "charon" = nixpkgs-charon.lib.nixosSystem rec {
        system = "aarch64-linux";
        specialArgs = {
          inherit self;
          inherit sensitive;
        };
        pkgs = import nixpkgs-charon {
          inherit system;
        };
        modules = [
          nixos-sbc.nixosModules.default
          nixos-sbc.nixosModules.boards.bananapi.bpir3
          inputs.sops.nixosModules.default
          {
            sbc = {
              version = "0.3";
              wireless.wifi.acceptRegulatoryResponsibility = true;
            };
          }
          ./modules
          ./systems/network/charon/configuration.nix
        ];
      };
      "citadel" = nixpkgs-charon.lib.nixosSystem rec {
        system = "aarch64-linux";
        specialArgs = {
          inherit self;
          inherit sensitive;
        };
        pkgs = import nixpkgs-charon {
          inherit system;
        };
        modules = [
          nixos-sbc.nixosModules.default
          nixos-sbc.nixosModules.boards.bananapi.bpir3
          inputs.sops.nixosModules.default
          {
            sbc = {
              version = "0.3";
              wireless.wifi.acceptRegulatoryResponsibility = true;
            };
          }
          ./modules
          ./systems/network/citadel/configuration.nix
        ];
      };
      "wsl" = inputs.nixpkgs-wsl.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = {
          inherit self;
          inherit sensitive;
        };
        pkgs = import inputs.nixpkgs-wsl {
          inherit system;
          overlays = [
            (final: prev: {
              nixvim = inputs.nixvim-config.packages.${prev.system}.nixvim-nightly-config;
            })
            (final: prev: {
              nixvim-light = inputs.nixvim-config.packages.${prev.system}.nixvim-light-config;
            })
          ];
        };
        modules = [
          nixos-wsl.nixosModules.default
          inputs.sops.nixosModules.default
          inputs.home-manager-wsl.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.jonboh = {
              imports = [./home-manager/wsl.nix];
            };
          }
          ./modules
          ./systems/wsl/configuration.nix
        ];
      };
    };

    hydraJobs = let
      configNames = [
        "workstation"
        "lab"
        "laptop"
        "tars"
        "bragi"
        "forge"
        "brick"
        "palantir"
        "sentinel"
        "eva"
        "charon"
        "citadel"
        "wsl"
      ];
      machineBuilds = builtins.listToAttrs (map (name: {
          inherit name;
          value = self.nixosConfigurations.${name}.config.system.build.toplevel;
        })
        configNames);
    in
      machineBuilds // self.devShells.x86_64-linux;
  };
}
