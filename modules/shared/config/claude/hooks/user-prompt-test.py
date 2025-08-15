#!/usr/bin/env python3
import json
import sys
import datetime

# Log to file
with open("/tmp/claude-user-prompt-log.txt", "a") as f:
    f.write(f"\n{datetime.datetime.now()}: User prompt hook triggered\n")

# Read input
try:
    input_data = json.load(sys.stdin)
    with open("/tmp/claude-user-prompt-log.txt", "a") as f:
        f.write(f"Input data: {json.dumps(input_data, indent=2)}\n")
except Exception as e:
    with open("/tmp/claude-user-prompt-log.txt", "a") as f:
        f.write(f"Error reading input: {str(e)}\n")

# Always allow
response = {
    "action": "allow",
    "message": "User prompt logged"
}
print(json.dumps(response))
sys.exit(0)
