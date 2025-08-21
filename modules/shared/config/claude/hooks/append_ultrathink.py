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
        stripped_prompt = prompt.strip()

        # Check if -u flag is present
        has_u_flag = stripped_prompt.endswith(" -u") or stripped_prompt == "-u"

        if has_u_flag:
            # Remove -u flag from prompt
            if stripped_prompt == "-u":
                clean_prompt = ""
            else:
                clean_prompt = stripped_prompt[:-3].rstrip()

            # Update the prompt in input_data
            input_data["prompt"] = clean_prompt

            # Add ultrathink context to stdout (Claude will see this as context)
            print(ULTRATHINK_MESSAGE)
            print("---")  # Separator for clarity

            # Output the modified input data as JSON
            print(json.dumps(input_data))
        else:
            # No -u flag, pass through unchanged
            print(json.dumps(input_data))

        sys.exit(0)

    except json.JSONDecodeError as e:
        print(f"Error parsing JSON input: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
