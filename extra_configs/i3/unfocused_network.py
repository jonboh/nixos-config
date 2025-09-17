import json
import subprocess


def is_unfocused():
    result = subprocess.run(
        ["rg", "youtube", "/etc/hosts"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    return result.returncode


if __name__ == "__main__":
    empty = json.dumps({"text": "", "state": "Idle"})
    if is_unfocused():
        message = {"text": f"\ue83d Unfocused", "state": "Warning"}
        print(json.dumps(message))
    else:
        print(empty)
