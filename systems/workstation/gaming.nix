{
  pkgs,
  config,
  lib,
  sensitive,
  ...
}: {
  specialisation = {
    gaming = {
      configuration = {
        system.nixos.tags = ["gaming"];

        services.syncthing.enable = lib.mkForce false;
        services.ollama.enable = lib.mkForce false;
        services.nextjs-ollama-llm-ui.enable = lib.mkForce false;

        users.users.hermes = {
          isNormalUser = true;
          description = "hermes";
          extraGroups = ["networkmanager"];
          shell = pkgs.zsh;
          hashedPassword = sensitive.passwords.hermes;
        };
        home-manager.users.hermes = {
          imports = [../../home-manager/hermes.nix];
        };
        services.displayManager.autoLogin.user = lib.mkForce "hermes";

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

        hardware.nvidia.package = pkgs.nvidia-patch.patch-nvenc (pkgs.nvidia-patch.patch-fbc config.boot.kernelPackages.nvidiaPackages.stable);
        environment.systemPackages = with pkgs; [
          heroic
          mangohud
          config.hardware.nvidia.package.settings
        ];
      };
    };
  };
}
