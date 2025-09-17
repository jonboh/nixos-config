import sys
import time
from datetime import datetime

HELP_TEXT = """
atuin-export-zsh.py

Usage:
    python atuin-export-zsh.py < inputfile > outputfile

Description:
    Converts atuin list history to zsh history format.

Options:
    --help      Show this help message and exit.
"""

if "--help" in sys.argv or "-h" in sys.argv:
    print(HELP_TEXT)
    sys.exit(0)

formatted_history = list()
count = 0
for line in sys.stdin:
    count += 1
    # print(f"LINE {count} =>", line)
    line = line.rstrip()
    if not line:
        continue
    parts = line.split("\t")
    if len(parts) < 2:
        continue
    dt_str, cmd = parts[0], parts[1]
    # convert to epoch
    try:
        dt = datetime.strptime(dt_str, "%Y-%m-%d %H:%M:%S")
        epoch = int(time.mktime(dt.timetuple()))
        formatted_history.append(f": {epoch}:0;{cmd}")
    except ValueError:
        formatted_history[-1] += line

for line in formatted_history:
    print(line)
