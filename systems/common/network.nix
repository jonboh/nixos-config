{
  self,
  pkgs,
  lib,
  sensitive,
  ...
}: let
  minimal_kernel = self.inputs.nixos-sbc.packages.aarch64-linux.linuxPackages_6_16_bananaPiR3_minimal.kernel;
  kernel = minimal_kernel.override (
    prev: {
      # these are needed in order to filter traffic using tc and mirrorTrafic for suricata
      structuredExtraConfig = with lib.kernel;
        minimal_kernel.structuredExtraConfig
        // {
          NET_CLS = yes;
          NET_CLS_BASIC = module;
          NET_CLS_ROUTE4 = module;
          NET_CLS_FW = module;
          NET_CLS_U32 = module;
          NET_CLS_FLOW = module;
          NET_CLS_CGROUP = module;
          NET_CLS_BPF = module;
          NET_CLS_FLOWER = module;
          NET_CLS_MATCHALL = module;
          NET_CLS_ACT = yes;

          NET_SCH_INGRESS = module;
          NET_SCH_PRIO = module;
          NET_ACT_MIRRED = module;
        };
    }
  );
in {
  # Network devices specific configuration (Banana Pi R3 and similar network hardware)
  imports = [
    ./servers.nix
  ];
  configure.hardware-metrics.thermal_zone0-temperature.enable = true;

  # Override users configuration with network-specific password
  users.users.jonboh = {
    hashedPassword = sensitive.passwords.jonboh-network;
    extraGroups = ["wheel" "network"];
  };

  boot.kernelPackages = pkgs.linuxKernel.packagesFor kernel;
}
