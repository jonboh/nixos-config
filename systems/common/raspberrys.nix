{
  pkgs,
  lib,
  sensitive,
  ...
}: {
  imports = [
    ./servers.nix
  ];

  jonboh.configure = {
    ntpd-rs.enable = true;
    telegraf-metrics.hardware-metrics.thermal_zone0-temperature.enable = true;
  };
  hardware.enableRedistributableFirmware = true;

  users.users.jonboh = {
    hashedPassword = sensitive.passwords.jonboh-raspberries;
  };

  environment.systemPackages = with pkgs; [
    libraspberrypi # NOTE: vcgencmd needs sudo to run
  ];

  systemd.sleep.extraConfig = ''
    AllowSuspend=no
    AllowHibernation=no
    AllowHybridSleep=no
    AllowSuspendThenHibernate=no
  '';
}
