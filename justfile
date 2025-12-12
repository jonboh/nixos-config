# Compares the closure of a remote system through ssh
compare system:
    #!/usr/bin/env bash
    set -euo pipefail
    current_system_derivation="$(echo -n $(\ssh {{system}}.lan "realpath /nix/var/nix/profiles/system"))"
    nix build ".#nixosConfigurations.{{system}}.config.system.build.toplevel" -o /tmp/result-new-{{system}}
    # retrieve currently active closure
    nix-copy-closure --from jonboh@{{system}}.lan $current_system_derivation
    nix store diff-closures $current_system_derivation /tmp/result-new-{{system}}

# Compares the closure of the local system
compare-local system:
    #!/usr/bin/env bash
    set -euo pipefail
    nix build ".#nixosConfigurations.{{system}}.config.system.build.toplevel" -o /tmp/result-new-{{system}}
    # retrieve currently active closure
    current_system_derivation="$(realpath /nix/var/nix/profiles/system)"
    nix store diff-closures $current_system_derivation /tmp/result-new-{{system}}
