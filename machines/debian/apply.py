"""Prepare, validate, and apply Debian-native services from one fixed source."""

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import signal
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts/lib"))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import identity
from packages import install, preserve_service_startup, root, run, validate_declaration
from syncthing import check_wiki, load_policy, sync_wiki

REPO = Path(__file__).resolve().parents[2]


def bootstrap(config, key_file, key_ref):
    with preserve_service_startup():
        install(config, key_file)
    identity.prepare(key_file, key_ref, check_secrets)
    # Joining the tailnet is a once-per-host step (docs/adr/0005); it needs tailscaled running.
    root(["systemctl", "enable", "--now", "tailscaled.service"])
    remote_access("debian-enroll", key_file, "Tailscale enrollment failed")
    print("Bootstrap finished. Apply separately: ./switch.sh")


def remote_access(mode, key_file, failure):
    # This CLI suppresses secrets itself; preserve its actionable diagnostics.
    command = [
        sys.executable, str(REPO / "scripts/lib/remote_access.py"), mode,
        str(REPO / "machines/remote-access.json"),
        str(REPO / "secrets/remote-access.json"), str(key_file.resolve()),
    ]
    result = subprocess.run(command if os.geteuid() == 0 else ["sudo", "--", *command])
    if result.returncode:
        raise RuntimeError(failure)


def check_secrets(key_file):
    env = dict(os.environ, SOPS_AGE_KEY_FILE=str(key_file), SOPS_AGE_SSH_PRIVATE_KEY_FILE="/dev/null", SOPS_GPG_EXEC="false")
    for name in ("SOPS_AGE_KEY", "SOPS_AGE_KEY_CMD", "SOPS_AGE_SSH_PRIVATE_KEY_CMD"):
        env.pop(name, None)
    run(["sops", "--decrypt", str(REPO / "secrets/remote-access.json")], env=env)


def preflight(config, key_file):
    """Read-only native readiness, also called before Home Manager activation."""
    validate_declaration(config)
    policy = load_policy(REPO / "machines/syncthing.json")
    required = ("age-keygen", "sops", "systemctl", "syncthing", "rustdesk", "tailscale")
    if any(shutil.which(tool) is None for tool in required):
        raise RuntimeError("Native tools are missing: run ./bootstrap.sh")
    identity.check(key_file, check_secrets)
    run(["systemctl", "show-environment"])
    check_wiki(policy)
    return policy


def apply(config, key_file):
    policy = preflight(config, key_file)
    root(["systemctl", "enable", "--now", "tailscaled.service", "rustdesk.service"])
    remote_access("debian", key_file, "Remote-access configuration failed")
    print("Remote access applied. Device IDs and existing Tailscale sessions were preserved.")
    sync_wiki(policy)


def main():
    config = json.loads((REPO / "machines/remote-access.json").read_text())
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=["bootstrap", "switch", "check"])
    parser.add_argument("--build", action="store_true")
    args = parser.parse_args()
    key_file = Path(os.environ.get("SOPS_AGE_KEY_FILE", Path.home() / ".config/sops/age/keys.txt"))
    if args.build and args.mode != "switch":
        parser.error("--build is only valid with switch")
    if args.build:
        validate_declaration(config)
        load_policy(REPO / "machines/syncthing.json")
        print("Debian native declarations valid; no keys read or host changes made.")
    elif args.mode == "check":
        preflight(config, key_file)
        print("Debian native readiness checked; no host changes made.")
    elif args.mode == "bootstrap":
        key_ref = os.environ.get("DOTFILES_AGE_KEY_REF", config["ageKeyRef"])
        if not key_ref.startswith("op://"):
            raise RuntimeError("DOTFILES_AGE_KEY_REF must be a 1Password reference")
        bootstrap(config, key_file, key_ref)
    else:
        apply(config, key_file)


if __name__ == "__main__":
    def interrupted(number, _frame):
        raise SystemExit(128 + number)

    signal.signal(signal.SIGTERM, interrupted)
    signal.signal(signal.SIGINT, interrupted)
    try:
        main()
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
        message = str(error) if isinstance(error, RuntimeError) else "Check Debian support, tools, identity, and permissions"
        raise SystemExit(f"Remote-access apply failed: {message}. Secret output suppressed.")
