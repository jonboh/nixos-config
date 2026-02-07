{
  pkgs,
  lib,
  sensitive,
  ...
}: {
  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      trusted-users = ["root" "@wheel"];
      trusted-public-keys = [
        sensitive.keys.nix.workstation
        sensitive.keys.nix.hydra-lab
      ];
      substituters = [
        "https://nix-cache.jonboh.dev"
        "https://cache.nixos.org"
      ];
      allow-import-from-derivation = true;
      require-sigs = true;
    };
    package = pkgs.nixVersions.latest;
  };

  jonboh.configure = {
    telegraf-metrics = {
      enable = true;
      hardware-metrics.enable = true;
      process-metrics.enable = true;
    };
    vector-logging.enable = true;
  };

  time.timeZone = "Europe/Madrid";
  i18n.defaultLocale = "en_US.UTF-8";

  users.users.jonboh = {
    isNormalUser = true;
    description = "jonboh";
    extraGroups = ["wheel"];
    uid = 1000;
  };

  networking.firewall.enable = lib.mkDefault true;

  environment.pathsToLink = [
    # link all /share and /bin folders from packages into /run/current-system/sw/
    "/share"
    "/bin"
  ];

  programs.htop = {
    enable = true;
    # NOTE: usually you need to remove $HOME/.config/htop/htoprc
    settings = {
      fields = "0 48 17 18 38 39 40 2 46 47 49 111 1";
      hide_kernel_threads = 1;
      hide_userland_threads = 0;
      shadow_other_users = 0;
      show_thread_names = 1;
      show_program_path = 1;
      highlight_base_name = 1;
      highlight_deleted_exe = 1;
      highlight_megabytes = 1;
      highlight_threads = 1;
      highlight_changes = 1;
      highlight_changes_delay_secs = 2;
      enable_mouse = 1;
      delay = 10;
      header_layout = "two_50_50";
      column_meters_0 = "AllCPUs4 Memory DiskIO NetworkIO";
      column_meter_modes_0 = "1 1 2 2";
      column_meters_1 = "Tasks LoadAverage Uptime Systemd";
      column_meter_modes_1 = "2 2 2 2";
      tree_view = 1;
      sort_key = 46;
      sort_direction = -1;
    };
  };

  # Base system packages available on all systems
  environment.systemPackages = with pkgs; [
    vim
  ];
}
