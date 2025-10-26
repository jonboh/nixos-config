import signal
import subprocess
import sys

import hid

## Keyboard RAW HID Interface
vendor_id = 0xFEED
product_id = 0x0000

usage_page = 0xFF60
usage = 0x61
report_length = 32

file_path = "/tmp/keyboard_status"
signal_num = signal.SIGRTMIN + 1


def get_raw_hid_interface():
    device_interfaces = hid.enumerate(vendor_id, product_id)
    raw_hid_interfaces = [
        i
        for i in device_interfaces
        if i["usage_page"] == usage_page and i["usage"] == usage
    ]

    if len(raw_hid_interfaces) == 0:
        return None

    interface = hid.Device(path=raw_hid_interfaces[0]["path"])

    return interface


def send_raw_report(data):
    interface = get_raw_hid_interface()

    if interface is None:
        print("No device found")
        sys.exit(1)

    request_data = [0x00] * (report_length + 1)  # First byte is Report ID
    request_data[1 : len(data) + 1] = data
    request_report = bytes(request_data)

    try:
        interface.write(request_report)

        response_report = interface.read(report_length, timeout=100)
    finally:
        interface.close()
    return response_report


def listen_for_updates():
    interface = get_raw_hid_interface()
    if interface is None:
        print("No device found")
        sys.exit(1)
    while True:
        response_report = interface.read(report_length)
        response_str = response_report.rstrip(b"\x00").decode("ascii", errors="replace")
        with open(file_path, "w", encoding="ascii") as f:
            f.write(response_str)
            f.flush()
        print(f"response: {response_report}")
        subprocess.run(["pkill", "-{}".format(signal_num), "i3status-rs"])


if __name__ == "__main__":
    listen_for_updates()
