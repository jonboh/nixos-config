{lib, ...}: {
  options.home.symlink_flake = lib.mkOption {
    type = lib.types.bool;
    default = true;
  };
  options.home.computer = lib.mkOption {
    type = lib.types.enum ["laptop" "workstation" "lab" "hermes"];
  };
}
