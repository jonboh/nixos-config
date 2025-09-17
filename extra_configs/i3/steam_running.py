import json
import subprocess


def get_steam_pid():
    try:
        ls_process = subprocess.Popen(
            ["pgrep", "-f", "steam.sh"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        output, errors = ls_process.communicate()

        if ls_process.returncode == 0:
            return output.decode("utf-8").strip()
        else:
            return f""  # return code is 1 when process is not present
    except Exception as e:
        return "Exception on script"


if __name__ == "__main__":
    empty = json.dumps({"text": "", "state": "Idle"})
    try:
        running = get_steam_pid()
        if running:
            message = {"text": f"S: {running}", "state": "Warning"}
            print(json.dumps(message))
        else:
            print(empty)
    except:
        print(empty)
