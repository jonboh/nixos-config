import json
import os
import subprocess
import sys


def get_viae():
    down_state = {"text": f"󰌙 ", "state": "Critical"}
    if os.path.exists("/sys/class/net/wg0"):
        with open("/sys/class/net/wg0/operstate") as f:
            if f.read().strip() == "down":
                return down_state
        return {"text": f" ", "state": "Good"}
    else:
        return down_state


def get_mullvad():
    try:
        result = subprocess.run(
            ["mullvad", "status", "--json"], capture_output=True, text=True, check=True
        )

        output_json = json.loads(result.stdout)
        state = output_json.get("state")
        if state == "connected":
            return {"text": f" ", "color": "Idle"}
        else:
            return {"text": f" ", "state": "Warning"}
    except Exception:
        return {"text": f" ", "state": "Warning"}


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: vpn.py <mode>", file=sys.stderr)
        sys.exit(1)
    mode = sys.argv[1]
    if mode not in ["mullvad", "viae"]:
        print("Invalid mode. Use 'mullvad' or 'viae'.", file=sys.stderr)
        sys.exit(1)
    output = ""
    if mode == "mullvad":
        output = get_mullvad()
    if mode == "viae":
        output = get_viae()
    print(json.dumps(output))
