#!/usr/bin/env zsh
# substitution needs zsh!
# reconnect Bluetooth headset (hands-free bug helper)
usage() {
  echo "Usage: $0 <device fragment>"
  echo "       $0 -u | --update    update via installer"
  exit 1
}

case "$1" in
  -h|--help|"") usage ;;
esac

# ── connect device ─────────────────────────────────────────────────────────
matches=(${(f)"$(bluetoothctl devices | grep -i "$1")"})
(( ${#matches} == 0 )) && { echo "No device matching '$1'"; exit 1; }
(( ${#matches} > 1 )) && { echo "Multiple matches:"; printf '%s\n' $matches; exit 1; }

mac=$(echo $matches | awk '{print $2}')
name=$(echo $matches | cut -d' ' -f3-)
echo "Connecting to $name ($mac)…"
bluetoothctl disconnect "$mac"
sleep 1
bluetoothctl connect "$mac"
sleep 1
bluetoothctl disconnect "$mac"
sleep 1
bluetoothctl connect "$mac"
sleep 4

object_id=$(pw-cli ls | rg $name -C 10 | rg Sink -C 10 | rg '\w*id \d*,.*(.*\n)*.*Sink' --multiline | rg -o 'id \d+' | head -n 1 | cut -d ' ' -f 2)
codec=$(pw-cli i $object_id | rg -o "codec = .*" | cut -d '"' -f 2)
echo "$name codec: $codec"
