#!/usr/bin/env python3

import json
import sys

ULTRATHINK_MESSAGE = (
    "Use the maximum amount of ultrathink. Take all the time you need. "
    "It's much better if you do too much research and thinking than not enough."
)

def main():
    try:
        # Read input from stdin
        input_data = json.loads(sys.stdin.read())

        # Get the prompt
        prompt = input_data.get("prompt", "")

        # Check if -u flag is present
        stripped_prompt = prompt.strip()
        if stripped_prompt.endswith(" -u") or stripped_prompt == "-u":
            # Remove -u flag from original prompt and add ultrathink context
            if stripped_prompt == "-u":
                clean_prompt = ""
            else:
                clean_prompt = stripped_prompt[:-3].rstrip()

            # Output the clean prompt and ultrathink message as context
            print(f"{clean_prompt}\n\n{ULTRATHINK_MESSAGE}")
        else:
            # No -u flag, just pass through
            print(json.dumps(input_data))

    except json.JSONDecodeError as e:
        print(f"Error parsing JSON input: {e}", file=sys.stderr)
        sys.exit(1)
    except KeyError as e:
        print(f"Missing required key in input: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
