#!/usr/bin/env zsh
usage() {
  echo "Usage: $0 <device fragment>"
  exit 1
}

case "$1" in
  -h|--help|"") usage ;;
esac
matches=(${(f)"$(bluetoothctl devices | grep -i "$1")"})
(( ${#matches} == 0 )) && { echo "No device matching '$1'"; exit 1; }
(( ${#matches} > 1 )) && { echo "Multiple matches:"; printf '%s\n' $matches; exit 1; }

mac=$(echo $matches | awk '{print $2}')
name=$(echo $matches | cut -d' ' -f3-)

object_id=$(pw-cli ls | rg $name -C 10 | rg Sink -C 10 | rg '\w*id \d*,.*(.*\n)*.*Sink' --multiline | rg -o 'id \d+' | head -n 1 | cut -d ' ' -f 2)
codec=$(pw-cli i $object_id | rg -o "codec = .*" | cut -d '"' -f 2)
echo "$name codec: $codec"
