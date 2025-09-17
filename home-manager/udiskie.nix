{
  # Automount removable media
  services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
    tray = "never";
    settings = {
      program_options = {
        udisks_version = 2;
        tray = false;
      };
      icon_names.media = ["media-optical"];
    };
  };
}
