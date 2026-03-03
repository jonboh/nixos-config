#!/usr/bin/env bash

# List of hosts
hosts=(
    "tars.lan"
    "bragi.lan"
    "forge.lan"
    "lab.lan"
    "thule.jonboh.dev"
    "alesia.lan"
    "charon.lan"
    "citadel.lan"
)

# Command to run on each host
command="shpool list"

# Colors
green_bold="\033[1;32m"
red_bold="\033[1;31m"
reset_color="\033[0m"

# Function to execute the command on a single host
execute_on_host() {
    local host=$1
    local tempfile=$2
    ssh "$host" "$command" 2>/dev/null | tail -n +2 | awk -v host="$host" -v green_bold="$green_bold" -v red_bold="$red_bold" -v reset_color="$reset_color" '{
        host_formatted =  green_bold host reset_color "{" red_bold $1 reset_color "}"
        printf "%-45s %-20s\t%s\n", host_formatted, $2, $3
    }' > "$tempfile"
}

# Create a temporary directory to store output files
tempdir=$(mktemp -d)

# Run the command on all hosts in background and store the PIDs
pids=()
tempfiles=()
for host in "${hosts[@]}"; do
    tempfile=$(mktemp "$tempdir/output.XXXXXX")
    execute_on_host "$host" "$tempfile" &
    pids+=($!)
    tempfiles+=("$tempfile")
done

# Wait for all background processes to finish
for pid in "${pids[@]}"; do
    wait "$pid"
done

# Print the results from all temporary files
for tempfile in "${tempfiles[@]}"; do
    cat "$tempfile"
    rm "$tempfile"
done

# Clean up temporary directory
rmdir "$tempdir"
