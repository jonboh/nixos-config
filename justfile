bump-update-branches:
    ssh tars.lan sudo systemctl restart flake-update-nixos-config-update-network.service
    ssh tars.lan sudo systemctl restart flake-update-nixos-config-update-all.service
