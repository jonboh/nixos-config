#!/usr/bin/env python

import glob
import json
import os
import re
import socket
import subprocess
import sys
from dataclasses import dataclass
from typing import Optional

import hid  # dependency: pyhidapi

YELLOW = "#e0af68"
RED = "#f7768e"
GREEN = "#9ece6a"
WHITE = None

hostname = socket.gethostname()

## Keyboard RAW HID Interface
vendor_id = 0xFEED
product_id = 0x0000

usage_page = 0xFF60
usage = 0x61
report_length = 32


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

    # print(f"Manufacturer: {interface.manufacturer}")
    # print(f"Product: {interface.product}")

    return interface


def send_raw_report(data):
    interface = get_raw_hid_interface()

    if interface is None:
        print("No device found")
        sys.exit(1)

    request_data = [0x00] * (report_length + 1)  # First byte is Report ID
    request_data[1 : len(data) + 1] = data
    request_report = bytes(request_data)

    # print("Request:")
    # print(request_report)
    try:
        interface.write(request_report)

        response_report = interface.read(report_length, timeout=100)

        # print("Response:")
        # print(response_report)
    finally:
        interface.close()
    return response_report


def get_mouse_state():
    whitespace = " " * 30
    if chr(send_raw_report([0x00])[0]) == "M":
        return {
            "full_text": f"MOUSE{whitespace}MOUSE",
            "color": WHITE,
            "background": GREEN,
        }
    else:
        return {"full_text": f"{whitespace}     ", "color": WHITE, "background": WHITE}


def get_vpn():
    g = glob.glob("/sys/class/net/vpn*", recursive=False)
    text = ""
    if os.path.exists("/sys/class/net/wg-mullvad"):
        text += "WG-VPN"
    if os.path.exists("/sys/class/net/wg0-mullvad"):
        text += "WG-VPN"
    if os.path.exists("/sys/class/net/tun0"):
        text += "OV-VPN"
    if text == "WG-VPN" or text == "OV-VPN":
        color = WHITE
    else:
        color = RED
    if text == "":
        text = "NO VPN"
    return {"full_text": f"  {text}", "color": color}


def color_for_available(available, units):
    if units == "TiB":
        available *= 1024
    elif units != "GiB":
        return RED
    if available < 50:
        return RED
    if available < 100:
        return YELLOW
    return WHITE


@dataclass
class Temperatures:
    cpu: Optional[float] = None
    gpu: Optional[float] = None
    sdd: Optional[float] = None

    cpu_color: Optional[str] = WHITE
    sdd_color: Optional[str] = WHITE


@dataclass
class NvidiaMetrics:
    utilization: Optional[float] = None
    temp: Optional[float] = None


def get_nvidia_gpu_metrics():
    metrics = NvidiaMetrics()
    try:
        result = subprocess.check_output(
            [
                "nvidia-smi",
                "--query-gpu=temperature.gpu,utilization.gpu",
                "--format=csv,noheader,nounits",
            ],
            encoding="utf-8",
        )

        temp_match = re.search(r"(\d+), (\d+)", result)
        if temp_match:
            metrics.temp = int(temp_match.group(1))
            metrics.utilization = int(temp_match.group(2))
            return metrics
        else:
            raise ValueError("Could not parse GPU temperature from nvidia-smi output.")
    except Exception as e:
        return None


def write_gpu_metrics(gpu: NvidiaMetrics, j):
    cpu = {
        "full_text": f"󰡁 {gpu.utilization:02d}%  {gpu.temp}°C",
        "color": WHITE,
    }
    j.insert(6, cpu)


def get_temperatures():
    temps = Temperatures()
    if hostname == "workstation":
        with open("/sys/class/hwmon/hwmon2/temp1_input", "r") as file:
            temps.cpu = float(file.read()) / 1000
        with open("/sys/class/hwmon/hwmon0/temp1_input", "r") as file:
            temps.sdd = float(file.read()) / 1000
    return temps


def write_temperatures(temps: Temperatures, j):
    cpu = {
        "full_text": f"{temps.cpu:.0f}°C",
        "color": temps.cpu_color,
    }
    sdd = {
        "full_text": f"{temps.sdd:.0f}°C",
        "color": temps.sdd_color,
    }
    j.insert(3, sdd)
    j.insert(5, cpu)


def print_line(message):
    """Non-buffered printing to stdout."""
    sys.stdout.write(message + "\n")
    sys.stdout.flush()


def read_line():
    """Interrupted respecting reader for stdin."""
    # try reading a line, removing any extra whitespace
    try:
        line = sys.stdin.readline().strip()
        # i3status sends EOF, or an empty line
        if not line:
            sys.exit(3)
        return line
    # exit on ctrl-c
    except KeyboardInterrupt:
        sys.exit()


def get_vault_conflicts():
    try:
        ls_process = subprocess.Popen(
            ["ls", "/home/jonboh/vault"], stdout=subprocess.PIPE
        )
        rg_process = subprocess.Popen(
            ["rg", "sync-conflict"], stdin=ls_process.stdout, stdout=subprocess.PIPE
        )
        ls_process.stdout.close()  # Allow ls_process to receive a SIGPIPE if rg_process exits.
        end_of_pipe = subprocess.Popen(
            ["wc", "-l"], stdin=rg_process.stdout, stdout=subprocess.PIPE
        )
        rg_process.stdout.close()  # Allow rg_process to receive a SIGPIPE if wc exits.
        output = end_of_pipe.communicate()[0]
        lines_count = output.decode("utf-8").strip()
        if lines_count == "0":
            return {"full_text": "", "color": WHITE}
        else:
            return {"full_text": f" CONFLICT {lines_count}", "color": RED}
    except Exception as e:
        print(f"An error while getting vault sync conflicts: {e}")


if __name__ == "__main__":
    # NOTE: test with
    # i3status --config ./i3status.conf | ./custom_i3status.py

    # Skip the first line which contains the version header.
    print_line(read_line())

    # The second line contains the start of the infinite array.
    print_line(read_line())

    while True:
        line, prefix = read_line(), ""
        # ignore comma at start of lines
        if line.startswith(","):
            line, prefix = line[1:], ","

        j = json.loads(line)
        for item in j:
            if "name" in item and item["name"] == "disk_info" and "full_text" in item:
                available, units = item["full_text"].split(" ")[-2:]
                available = float(available.replace(",", "."))
                item["color"] = color_for_available(available, units)
        # insert information into the start of the json, but could be anywhere
        j.insert(7, get_vpn())

        if hostname == "workstation":
            temps = get_temperatures()
            write_temperatures(temps, j)
            gpu = get_nvidia_gpu_metrics()
            if gpu:
                write_gpu_metrics(gpu, j)
        j.insert(0, get_mouse_state())
        j.insert(0, get_vault_conflicts())
        # and echo back new encoded json
        print_line(prefix + json.dumps(j))
