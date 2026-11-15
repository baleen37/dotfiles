"""Converge the shared wiki policy without deleting unrelated user configuration."""

import getpass
import json
import os
from pathlib import Path
import stat
import subprocess
import tempfile
import time

from packages import root, run

BEGIN = "// BEGIN dotfiles managed ignores"
END = "// END dotfiles managed ignores"


def load_policy(path):
    policy = json.loads(path.read_text())
    wiki = policy.get("wiki", {})
    hub = policy.get("hub", {})
    patterns = wiki.get("ignorePatterns")
    if (not isinstance(hub, dict) or not hub or not all(isinstance(value, str) and value for value in hub.values())
            or not isinstance(wiki.get("path"), str) or not wiki["path"].startswith("~/")
            or not isinstance(patterns, list) or not patterns
            or not all(isinstance(value, str) and value and "\n" not in value for value in patterns)):
        raise RuntimeError("Invalid shared Syncthing declaration")
    return policy


def ignore_content(existing, patterns):
    """Keep manual rules, but mandatory shared excludes must precede negations."""
    lines = existing.splitlines()
    if BEGIN in lines or END in lines:
        if lines.count(BEGIN) != 1 or lines.count(END) != 1 or lines.index(BEGIN) > lines.index(END):
            raise RuntimeError("Malformed managed Syncthing ignore block; repair it before switching")
        start, end = lines.index(BEGIN), lines.index(END)
        lines = lines[:start] + lines[end + 1:]
    # Syncthing requires an escape directive before any patterns.
    header = []
    directives = [line for line in lines if line.startswith("#escape=")]
    if directives:
        if len(directives) != 1:
            raise RuntimeError("Multiple Syncthing escape directives")
        directive = directives[0]
        if any(line.strip() and not line.startswith("//") for line in lines[:lines.index(directive)]):
            raise RuntimeError("Syncthing escape directive must precede patterns")
        header = [directive]
        lines.remove(directive)
    return "\n".join([*header, BEGIN, *patterns, END, *lines]) + "\n"


def check_wiki(policy):
    folder = Path(policy["wiki"]["path"]).expanduser()
    if folder.exists() and not folder.is_dir():
        raise RuntimeError("Configured wiki path is not a directory")
    target = folder / ".stignore"
    if target.is_symlink() or (target.exists() and not target.is_file()):
        raise RuntimeError("Syncthing .stignore must be a regular file")
    existing = target.read_text() if target.exists() else ""
    ignore_content(existing, policy["wiki"]["ignorePatterns"])
    return folder


def ensure_ignores(policy):
    folder = check_wiki(policy)
    target = folder / ".stignore"
    previous = target.read_text() if target.exists() else ""
    content = ignore_content(previous, policy["wiki"]["ignorePatterns"])
    if previous == content:
        return
    folder.mkdir(parents=True, exist_ok=True)
    mode = stat.S_IMODE(target.stat().st_mode) if target.exists() else 0o600
    descriptor, name = tempfile.mkstemp(prefix=".dotfiles-ignore-", dir=folder)
    try:
        with os.fdopen(descriptor, "w") as stream:
            stream.write(content)
        os.chmod(name, mode)
        os.replace(name, target)
    finally:
        Path(name).unlink(missing_ok=True)


def sync_wiki(policy):
    hub = policy["hub"]
    root(["systemctl", "enable", "--now", f"syncthing@{getpass.getuser()}.service"])
    for _ in range(30):
        if subprocess.run(["syncthing", "cli", "show", "system"], capture_output=True).returncode == 0:
            break
        time.sleep(1)
    else:
        raise RuntimeError("Syncthing did not start")

    def config(*args):
        return run(["syncthing", "cli", "config", *args])

    wiki = str(check_wiki(policy))
    exists = "wiki" in config("folders", "list").split()
    if exists and config("folders", "wiki", "path", "get") != wiki:
        raise RuntimeError(f"Syncthing folder 'wiki' does not point to {wiki}")
    # Install excludes before registering/sharing a new folder.
    ensure_ignores(policy)
    for name, device in hub.items():
        if device not in config("devices", "list").split():
            config("devices", "add", "--device-id", device, "--name", name)
    if not exists:
        config("folders", "add", "--id", "wiki", "--label", "wiki", "--path", wiki)
    for device in hub.values():
        if device not in config("folders", "wiki", "devices", "list").split():
            config("folders", "wiki", "devices", "add", "--device-id", device)
    device_id = json.loads(run(["syncthing", "cli", "show", "system"]))["myID"]
    print(f"~/wiki shared with the Syncthing hub. Add this device there: {device_id}")
