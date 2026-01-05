{lib, ...}: {
  hardware.raspberry-pi.config = {
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
      "uart0" = {
        # UART on GPIO 14/15 /dev/ttyAMA0
        # /dev/ttyAMA10
        enable = true;
        params = {};
      };
      "uart1" = {
        # UART on GPIO 0/1 /dev/ttyAMA1
        enable = true;
        params = {};
      };
    };

    all = {
      options = {
        # Enable UART (on by default, but forced all the same)
        enable_uart = lib.mkForce {
          enable = true;
          value = 1;
        };
      };
    };
  };
}
