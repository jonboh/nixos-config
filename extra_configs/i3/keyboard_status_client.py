import json
import os


def make_active_mouse_json():
    whitespace = " " * 10
    return {"text": f"{whitespace}MOUSE {whitespace}", "state": "Critical"}


def make_active_scroll_json():
    whitespace = " " * 10
    return {"text": f"{whitespace}SCROLL{whitespace}", "state": "Warning"}


if __name__ == "__main__":
    file_path = "/tmp/keyboard_status"

    if os.path.exists(file_path):
        with open(file_path, "r") as file:
            keyboard_status = file.read().strip()
            if keyboard_status == "M":
                print(json.dumps(make_active_mouse_json()))
            elif keyboard_status == "S":
                print(json.dumps(make_active_scroll_json()))
            else:
                print("{}")
