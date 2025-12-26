{
  pkgs,
  lib,
  sensitive,
  ...
}: {
  imports = [
    ./servers.nix
  ];

  configure.hardware-metrics.thermal_zone0-temperature.enable = true;
  hardware.enableRedistributableFirmware = true;

  configure.ntpd-rs.enable = true;

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
