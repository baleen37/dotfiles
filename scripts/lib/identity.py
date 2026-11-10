"""Validate and restore an existing age identity without replacing another key."""

import argparse
import json
import os
from pathlib import Path
import subprocess
import signal
import sys
import tempfile


def run(args, **kwargs):
    result = subprocess.run(args, capture_output=True, text=True, **kwargs)
    if result.returncode:
        raise RuntimeError(f"Identity command failed: {Path(args[0]).name}")
    return result.stdout.strip()


def check(key, checker=None):
    if key.is_symlink() or not key.is_file() or not key.stat().st_size:
        raise RuntimeError("Missing or invalid age key: run ./bootstrap.sh")
    try:
        run(["age-keygen", "-y", str(key)])
    except RuntimeError:
        raise RuntimeError("age identity is invalid; it was not replaced") from None
    if checker:
        checker(key)


def authenticate():
    os.environ.setdefault("OP_BIOMETRIC_UNLOCK_ENABLED", "true")
    run(["op", "--version"])

    def signed_in():
        return subprocess.run(["op", "whoami"], capture_output=True).returncode == 0

    if signed_in():
        return
    if os.environ["OP_BIOMETRIC_UNLOCK_ENABLED"] == "true":
        subprocess.run(["op", "signin"], stdout=subprocess.DEVNULL, check=False)
        if signed_in():
            return
    os.environ["OP_BIOMETRIC_UNLOCK_ENABLED"] = "false"
    if signed_in():
        return
    if not sys.stdin.isatty():
        raise RuntimeError("1Password CLI authentication required; rerun bootstrap in a terminal")
    if not json.loads(run(["op", "account", "list", "--format=json"])):
        print("Add your 1Password account in this terminal.")
        if subprocess.run(["op", "account", "add"]).returncode:
            raise RuntimeError("1Password account registration failed")
    session = run(["op", "signin", "--raw"])
    if not session:
        raise RuntimeError("1Password CLI returned an empty session")
    os.environ["OP_SESSION"] = session
    if not signed_in():
        raise RuntimeError("1Password CLI authentication failed")


def prepare(key, reference, checker=None):
    if not reference.startswith("op://"):
        raise RuntimeError("Expected an op:// reference, never the private key")
    if key.exists() or key.is_symlink():
        check(key, checker)
        key.chmod(0o600)
        print("Existing age key validated; preserved.")
        return
    authenticate()
    key.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    key.parent.chmod(0o700)
    descriptor, name = tempfile.mkstemp(prefix=".age-key.", dir=key.parent)
    os.close(descriptor)
    temporary = Path(name)
    try:
        run(["op", "read", reference, "--out-file", name, "--file-mode", "0600", "--force"])
        check(temporary, checker)
        try:
            os.link(temporary, key)
        except FileExistsError:
            raise RuntimeError("age key destination now exists; it was not replaced") from None
    finally:
        temporary.unlink(missing_ok=True)
    print("Age key supplied and validated.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=["check", "prepare"])
    parser.add_argument("key", type=Path)
    parser.add_argument("arguments", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    command = args.arguments
    if args.mode == "prepare":
        reference, *command = command
    checker = (lambda key: run([*command, str(key)])) if command else None
    if args.mode == "prepare":
        prepare(args.key, reference, checker)
    else:
        check(args.key, checker)


if __name__ == "__main__":
    def interrupted(number, _frame):
        raise SystemExit(128 + number)

    signal.signal(signal.SIGTERM, interrupted)
    signal.signal(signal.SIGINT, interrupted)
    try:
        main()
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
        message = str(error) if isinstance(error, RuntimeError) else "Check identity, tools, and permissions"
        raise SystemExit(f"Identity not ready: {message}. Secret output suppressed.")
