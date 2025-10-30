import re
import sys

# Define substitution mappings and placeholder
FORWARD_SLASH = "/"
BACKSLASH = "\\"
PLACEHOLDER = "<<<SWAP_PLACEHOLDER>>>"

# Partition can be short hash or >=10 whitespaces
partition_re = re.compile(r"([0-9a-f]{7,12})|(\s{10,})")


def substitute_before_partition(line):
    match = partition_re.search(line)
    if match:
        idx = match.start()
        before = line[:idx]
        after = line[idx:]
    else:
        before = line
        after = ""
    before = before.replace(FORWARD_SLASH, PLACEHOLDER)
    before = before.replace(BACKSLASH, FORWARD_SLASH)
    before = before.replace(PLACEHOLDER, BACKSLASH)
    before = before.replace("_", " \u0305")

    return before + after


if __name__ == "__main__":
    for line in sys.stdin:
        print(substitute_before_partition(line.rstrip("\n")))
