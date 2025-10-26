import json
import os


def make_active_mouse_json():
    whitespace = " " * 7
    return {"text": f"{whitespace}    MOUSE    {whitespace}", "state": "Critical"}


def make_active_mouse_snipe_json():
    whitespace = " " * 7
    return {"text": f"{whitespace} MOUSE SNIPE {whitespace}", "state": "Critical"}


def make_active_scroll_json():
    whitespace = " " * 7
    return {"text": f"{whitespace}   SCROLL    {whitespace}", "state": "Warning"}


if __name__ == "__main__":
    file_path = "/tmp/keyboard_status"

    if os.path.exists(file_path):
        with open(file_path, "r") as file:
            keyboard_status = file.read().strip()
            if keyboard_status == "Mouse":
                print(json.dumps(make_active_mouse_json()))
            elif keyboard_status == "MouseSnipe":
                print(json.dumps(make_active_mouse_snipe_json()))
            elif keyboard_status == "MouseScroll":
                print(json.dumps(make_active_scroll_json()))
            else:
                print("{}")
