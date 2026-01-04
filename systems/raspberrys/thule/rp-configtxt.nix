{lib, ...}: {
  hardware.raspberry-pi.config = {
    # see: https://github.com/raspberrypi/firmware/blob/master/boot/overlays/README#L3880
    pi5.base-dt-params = {
      "pciex1" = {
        enable = true;
      };
      "pciex1_gen" = {
        enable = true;
        value = 3;
      };
    };
  };
}
