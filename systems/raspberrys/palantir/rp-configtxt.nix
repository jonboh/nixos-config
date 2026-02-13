{
  hardware.raspberry-pi = {
    config = {
      # see: https://github.com/raspberrypi/firmware/blob/master/boot/overlays/README#L3880
      pi5.dt-overlays = {
        "pwm,pin=12,func=4" = {
          enable = true;
          params = {};
        };
        "pwm,pin=18,func=2" = {
          enable = true;
          params = {};
        };
      };
    };
    # NOTE: rpi5 ignores gpu_mem config.txt configurations. see: https://www.raspberrypi.com/documentation/computers/legacy_config_txt.html#legacy-memory-options
  };
}
