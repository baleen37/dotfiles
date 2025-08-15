#!/usr/bin/env python3
import sys
import datetime

# Simple hook that just logs to a file
with open("/tmp/simple-hook.log", "a") as f:
    f.write(f"[{datetime.datetime.now()}] Simple hook called\n")

# Always allow the command
sys.exit(0)
