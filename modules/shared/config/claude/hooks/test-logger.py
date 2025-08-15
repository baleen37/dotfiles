#!/usr/bin/env python3
import json
import sys
import datetime

# Log to file
with open("/tmp/claude-hook-log.txt", "a") as f:
    f.write(f"{datetime.datetime.now()}: Hook executed\n")

# Read input
try:
    input_data = json.load(sys.stdin)
    with open("/tmp/claude-hook-log.txt", "a") as f:
        f.write(f"Tool: {input_data.get('tool_name', 'Unknown')}\n")
        f.write(f"Command: {input_data.get('tool_input', {}).get('command', 'N/A')}\n\n")
except:
    pass

# Always allow
sys.exit(0)
