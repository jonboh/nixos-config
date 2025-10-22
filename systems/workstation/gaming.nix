{
  pkgs,
  config,
  lib,
  ...
}: {
  specialisation = {
    gaming = {
      configuration = {
        system.nixos.tags = ["gaming"];

        services.syncthing.enable = lib.mkForce false;
        services.ollama.enable = lib.mkForce false;
        services.nextjs-ollama-llm-ui.enable = lib.mkForce false;
        virtualisation.podman.enable = lib.mkForce false;

        programs.steam = {
          enable = true;
        };
        programs.gamemode.enable = true;

        services.sunshine = {
          autoStart = true;
          enable = true;
          openFirewall = true;
          package = pkgs.sunshine.override {cudaSupport = true;};
        };

        # hardware.nvidia.package = pkgs.nvidia-patch.patch-nvenc (pkgs.nvidia-patch.patch-fbc config.boot.kernelPackages.nvidiaPackages.stable);
        environment.systemPackages = with pkgs; [
          heroic
          mangohud
        ];
      };
    };
  };
}
