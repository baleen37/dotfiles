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

        # Check if prompt ends with -u flag (as a separate word)
        stripped_prompt = prompt.strip()
        if stripped_prompt.endswith(" -u"):
            # Remove the -u flag
            clean_prompt = stripped_prompt[:-3].rstrip()

            # Append ultrathink message
            prompt = f"{clean_prompt}\n\n{ULTRATHINK_MESSAGE}"

            # Update the input data
            input_data["prompt"] = prompt
        elif stripped_prompt == "-u":
            # Handle case where prompt is just "-u"
            prompt = f"\n\n{ULTRATHINK_MESSAGE}"

            # Update the input data
            input_data["prompt"] = prompt

        # Output the modified (or original) data
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
