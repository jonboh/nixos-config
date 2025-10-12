{sensitive, ...}: {
  services.vsftpd = {
    enable = true;
    localUsers = true;
    userlist = ["hartaman"];
    writeEnable = true;
    localRoot = "/mnt/storage/music/hartaman";
    rsaCertFile = "/var/lib/acme/jonboh.dev/fullchain.pem";
    rsaKeyFile = "/var/lib/acme/jonboh.dev/key.pem";
    extraConfig = ''
      listen_port=${toString sensitive.network.port.tcp.bragi.ftp.main}
      pasv_min_port=${toString sensitive.network.port.tcp.bragi.ftp.passive.min}
      pasv_max_port=${toString sensitive.network.port.tcp.bragi.ftp.passive.max}
      file_open_mode=0644
      local_umask=022
    '';
  };

  users.users.hartaman = {
    isNormalUser = true;
    createHome = false;
    home = "/mnt/storage/music/hartaman";
    shell = "/run/current-system/sw/bin/nologin";
    group = "ftpusers";
    extraGroups = [];
    hashedPassword = sensitive.passwords.hartaman-ftp;
  };

  users.groups.ftpusers = {};
}
