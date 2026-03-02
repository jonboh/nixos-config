{
  pkgs,
  lib,
  sensitive,
}: let
  # Extract all device-IP pairs from sensitive.network.ip
  allPairs = lib.flatten (
    lib.mapAttrsToList (
      deviceName: networks:
        lib.mapAttrsToList (
          networkName: ip: {
            device = deviceName;
            network = networkName;
            inherit ip;
          }
        )
        networks
    )
    sensitive.network.ip
  );

  # Filter out entries with empty IPs or commented out entries
  validPairs = lib.filter (pair: pair.ip != null && pair.ip != "") allPairs;

  # Get unique network names for help text
  availableNetworks = lib.unique (map (pair: pair.network) validPairs);
  networksText = builtins.concatStringsSep ", " availableNetworks;

  # Generate ping commands data structure (we'll filter this at runtime)
  generatePingData = let
    pairToCommand = pair: {
      device = pair.device;
      network = pair.network;
      ip = pair.ip;
    };
  in
    map pairToCommand validPairs;
in
  pkgs.writeScriptBin "ping-devices" ''
    set -euo pipefail

    # Available networks: ${networksText}

    # Usage function
    show_help() {
        echo "Usage: ping-devices [NETWORK]"
        echo ""
        echo "Ping all network devices or devices on a specific network."
        echo ""
        echo "Arguments:"
        echo "  NETWORK    Optional. Ping only devices on the specified network."
        echo ""
        echo "Available networks: ${networksText}"
        echo ""
        echo "Examples:"
        echo "  ping-devices           # Ping all devices on all networks"
        echo "  ping-devices lab       # Ping only devices on the lab network"
        echo "  ping-devices viae      # Ping only devices on the viae network"
        echo ""
        echo "Options:"
        echo "  -h, --help    Show this help message"
    }

    # Parse arguments
    FILTER_NETWORK=""
    case "''${1:-}" in
        -h|--help)
            show_help
            exit 0
            ;;
        "")
            # No arguments, ping all networks
            ;;
        *)
            FILTER_NETWORK="$1"
            # Validate network name
            case "$FILTER_NETWORK" in
                ${lib.concatStringsSep "|" availableNetworks})
                    ;;
                *)
                    echo "Error: Unknown network '$FILTER_NETWORK'"
                    echo "Available networks: ${networksText}"
                    exit 1
                    ;;
            esac
            ;;
    esac

    # Colors for output
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color

    # Counters
    total_interfaces=0
    online_interfaces=0

    # Function to ping a device and report status
    ping_device() {
        local device="$1"
        local network="$2"
        local ip="$3"

        # Skip if filtering by network and this doesn't match
        if [ -n "$FILTER_NETWORK" ] && [ "$network" != "$FILTER_NETWORK" ]; then
            return 0
        fi

        total_interfaces=$((total_interfaces + 1))
        printf "%-15s %-10s %-15s " "$device" "$network" "$ip"

        if ping -c 1 -W 2 "$ip" >/dev/null 2>&1; then
            printf "''${GREEN}✓ ONLINE''${NC}\n"
            online_interfaces=$((online_interfaces + 1))
        else
            printf "''${RED}✗ OFFLINE''${NC}\n"
        fi
    }

    # Header
    if [ -n "$FILTER_NETWORK" ]; then
        echo "Network Device Connectivity Report ($FILTER_NETWORK network) - $(date)"
    else
        echo "Network Device Connectivity Report (all networks) - $(date)"
    fi
    echo "=============================================="

    echo "Individual device interfaces:"
    echo "Device          Network    IP Address      Status"
    echo "---------------------------------------------------"

    # Ping all devices (filtering happens in ping_device function)
    ${lib.concatStringsSep "\n    " (map (pair: ''ping_device "${pair.device}" "${pair.network}" "${pair.ip}"'') generatePingData)}

    echo
    echo "=============================================="
    echo "Summary:"
    if [ -n "$FILTER_NETWORK" ]; then
        echo "  Network: $FILTER_NETWORK"
    fi
    echo "  Total interfaces checked: $total_interfaces"
    printf "  Online interfaces: ''${GREEN}$online_interfaces''${NC}\n"
    printf "  Offline interfaces: ''${RED}$((total_interfaces - online_interfaces))''${NC}\n"

    # Calculate percentages
    if [ $total_interfaces -gt 0 ]; then
        online_percent=$((online_interfaces * 100 / total_interfaces))
        if [ $online_percent -ge 80 ]; then
            color="''${GREEN}"
        elif [ $online_percent -ge 50 ]; then
            color="''${YELLOW}"
        else
            color="''${RED}"
        fi
        printf "  Connectivity: ''${color}$online_percent%%''${NC}\n"
    elif [ -n "$FILTER_NETWORK" ]; then
        printf "  ''${YELLOW}No devices found on network '$FILTER_NETWORK'!''${NC}\n"
    fi

    echo
    if [ $total_interfaces -eq 0 ]; then
        if [ -n "$FILTER_NETWORK" ]; then
            printf "''${YELLOW}No devices found on network '$FILTER_NETWORK'.''${NC}\n"
        else
            printf "''${RED}No devices found to check.''${NC}\n"
        fi
        exit 1
    elif [ $online_interfaces -eq $total_interfaces ]; then
        printf "''${GREEN}All network interfaces are reachable!''${NC}\n"
        exit 0
    elif [ $online_interfaces -eq 0 ]; then
        printf "''${RED}No network interfaces are reachable.''${NC}\n"
        exit 1
    else
        printf "''${YELLOW}Some network interfaces are unreachable.''${NC}\n"
        exit 1
    fi
  ''
