#!/usr/bin/env bash

desired_devices=("USB Audio Speakers" "Leviathan" "Soundcore Space A40")

# Collect all output device properties
mapfile -t present_devices < <(pw-dump | jq -r '.[] | select(.info.props."media.class" == "Audio/Sink") | .info.props."node.description"')

# Filter only desired_devices that are present
cycle_devices=()
for dev in "${desired_devices[@]}"; do
    for present in "${present_devices[@]}"; do
        if [[ "$dev" == "$present" ]]; then
            cycle_devices+=("$dev")
        fi
    done
done

if [[ ${#cycle_devices[@]} -eq 0 ]]; then
    echo "No valid output devices available"
    exit 1
fi

current_default_device=$(pactl get-default-sink)
current_default_description=$(pw-dump | jq -r \
    ".[] | select(.info.props.\"media.class\" == \"Audio/Sink\") | select(.info.props.\"node.name\" == \"$current_default_device\") | .info.props.\"node.description\"")

# Find the index of current device in present cycle list
current_index=-1
for i in "${!cycle_devices[@]}"; do
    if [[ "${cycle_devices[$i]}" == "$current_default_description" ]]; then
        current_index=$i
        break
    fi
done

# Determine next index
if [[ $current_index -lt 0 ]]; then
    next_index=0
else
    next_index=$(( (current_index + 1) % ${#cycle_devices[@]} ))
fi
next_device="${cycle_devices[$next_index]}"

next_device_id=$(pw-dump | jq -r ".[] | select(.info.props.\"media.class\" == \"Audio/Sink\") | select(.info.props.\"node.description\" == \"$next_device\") | .id")

if [[ -n "$next_device_id" ]]; then
    wpctl set-default "$next_device_id"
else
    echo "Next device \"$next_device\" not found"
    exit 1
fi
