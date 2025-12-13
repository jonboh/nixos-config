#!/usr/bin/env bash

pwdump=$(pw-dump)

current_default_device=$(pactl get-default-sink)
current_default_id=$(pw-dump | jq -r ".[] | select(.info.props.\"media.class\" == \"Audio/Sink\") | select(.info.props.\"node.name\" == \"$current_default_device\") | .id")
current_default_description=$(pw-dump | jq -r ".[] | select(.info.props.\"media.class\" == \"Audio/Sink\") | select(.info.props.\"node.name\" == \"$current_default_device\") | .info.props.\"node.description\"")

# NOTE: get the list of valid descriptions with:
# pw-dump | jq -r '.[] | select(.info.props."media.class" == "Audio/Sink") | .info.props."node.description"'

case $current_default_description in
  "USB Audio Speakers")
      next_device="Leviathan"
    ;;
  "Leviathan")
      next_device="Soundcore Space A40"
    ;;
  "Soundcore Space A40")
      next_device="USB Audio Speakers"
    ;;
  *)
      next_device="USB Audio Speakers"
    ;;
esac

next_device_id=$(pw-dump | jq -r ".[] | select(.info.props.\"media.class\" == \"Audio/Sink\") | select(.info.props.\"node.description\" == \"$next_device\") | .id")

if [ -z "$next_device_id" ]; then
  next_device="USB Audio Speakers"
  next_device_id=$(pw-dump | jq -r ".[] | select(.info.props.\"media.class\" == \"Audio/Sink\") | select(.info.props.\"node.description\" == \"$next_device\") | .id")
fi

next_device_description=$(pw-dump | jq -r ".[] | select(.info.props.\"media.class\" == \"Audio/Sink\") | select(.info.props.\"node.description\" == \"$next_device\") | .info.props.\"node.description\"")
echo "$next_device_description"
wpctl set-default $next_device_id
