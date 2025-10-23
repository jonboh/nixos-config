import signal
import subprocess
import sys
import time

CHECK_INTERVAL = 5  # seconds between clipboard checks
CLEAR_TIMEOUT = 30  # seconds with unchanged clipboard before clearing


def get_clipboard():
    try:
        return subprocess.check_output(
            ["xclip", "-selection", "clipboard", "-o"]
        ).decode("utf-8")
    except subprocess.CalledProcessError:
        return ""


def clear_clipboard():
    subprocess.run(["xclip", "-selection", "clipboard", "-i"], input=b"", check=False)


def main():
    last_contents = get_clipboard()
    last_change_time = time.time()

    while True:
        time.sleep(CHECK_INTERVAL)

        current_contents = get_clipboard()
        if current_contents != last_contents:
            last_contents = current_contents
            last_change_time = time.time()
        elif current_contents and (time.time() - last_change_time) >= CLEAR_TIMEOUT:
            clear_clipboard()
            last_contents = ""
            last_change_time = time.time()


def signal_handler(sig, frame):
    sys.exit(0)


if __name__ == "__main__":
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    main()
