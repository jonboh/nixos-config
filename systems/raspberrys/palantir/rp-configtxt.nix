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
    extra-config = ''
      gpu_mem=256
      gpu_mem_256=128
      gpu_mem_512=256
      gpu_mem_1024=256
      
      # Enable camera and codec support
      start_x=1
      
      # Enable V4L2 drivers
      dtoverlay=vc4-kms-v3d-pi5
      
      # Enable video codec support
      dtparam=video=1
    '';
  };
}
