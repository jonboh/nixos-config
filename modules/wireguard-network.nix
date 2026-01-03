{
  self,
  pkgs,
  config,
  lib,
  sensitive,
  ...
}: {
  options = {
    jonboh.configure.wireguard = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      deviceName = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Name of the wireguard device, used to retrieve the appropriate keys and network addresses";
      };
      allowedNetworks = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "List of network names to which the device is allowed to connect, e.g. [ \"viae\" \"hodos\" ]";
      };
      keepAlive = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };
  };
  config = let
    deviceName = config.jonboh.configure.wireguard.deviceName;
    allowedIPs = map (net: sensitive.network.ip.alesia.${net} + "/24") config.jonboh.configure.wireguard.allowedNetworks;
    address = map (net: sensitive.network.ip.${deviceName}.${net} + "/32") config.jonboh.configure.wireguard.allowedNetworks;
  in
    lib.mkIf config.jonboh.configure.wireguard.enable {
      systemd.network.netdevs."50-wg0" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "wg0";
        };

        wireguardConfig = {
          ListenPort = sensitive.network.port.udp.alesia.wireguard;
          PrivateKeyFile = config.sops.secrets."wg-${deviceName}-private-key".path;
          RouteTable = "main"; # To automatically create routes for everything in AllowedIPs,
          FirewallMark = sensitive.network.wireguard.firewallMark;
        };
        wireguardPeers = [
          {
            PublicKey = sensitive.keys.wireguard.alesia.pub;
            PresharedKeyFile = config.sops.secrets."wg-${deviceName}-psk".path;
            AllowedIPs = allowedIPs;
            Endpoint = "${sensitive.network.ip.alesia.public}:${toString sensitive.network.port.udp.alesia.wireguard}";
            # NOTE: PersistentKeepalive needed to keep the channel between alesia and ${deviceName} alive.
            # Otherwise if a connection was not already in place (initiated by ${deviceName}) alesia would not
            # know where to route the requests from other peers to ${deviceName}
            PersistentKeepalive = 25;
          }
        ];
      };

      systemd.network.networks = {
        "50-wg0" = {
          matchConfig.Name = "wg0";
          inherit address;
        };
      };

      sops.secrets."wg-${deviceName}-private-key" = {
        format = "binary";
        sopsFile = self.inputs.nixos-config-sensitive + /secrets/wg-${deviceName}-private-key;
        mode = "640";
        owner = "systemd-network";
        group = "systemd-network";
      };
      sops.secrets."wg-${deviceName}-psk" = {
        format = "binary";
        sopsFile = self.inputs.nixos-config-sensitive + /secrets/wg-${deviceName}-psk;
        mode = "640";
        owner = "systemd-network";
        group = "systemd-network";
      };

      environment.systemPackages = [pkgs.wireguard-tools];
    };
}
