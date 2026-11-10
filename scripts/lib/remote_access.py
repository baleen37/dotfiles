"""Apply the shared remote-access policy once; package managers own installation."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import pwd
import shutil
import socket
import subprocess
import sys
import tempfile
import time


SOPS = shutil.which("sops") or "/usr/bin/sops"
RUSTDESK = "/usr/bin/rustdesk"
TAILSCALE = "/usr/bin/tailscale"
STATE = Path("/var/lib/dotfiles-remote")
RUNTIME = Path("/run")


def command(binary, *args):
    # RustDesk can return exit 0 on failure. Never log its output or argv:
    # the password command necessarily carries the secret in process arguments.
    result = subprocess.run(
        [binary, *args], capture_output=True, text=True, timeout=15, check=False
    )
    if result.returncode:
        raise RuntimeError("RustDesk command failed")
    return result.stdout.strip()


def configure_rustdesk(binary, password, state_file, options):
    password = password.rstrip("\r\n")
    if not password:
        raise RuntimeError("RustDesk secret is empty")
    revision = hashlib.sha256(
        (password + json.dumps(options, sort_keys=True) + str(Path(binary).stat().st_mtime_ns)).encode()
    ).hexdigest()
    applied = state_file.read_text() if state_file.exists() else ""
    if applied != revision:
        acknowledgement = command(binary, "--password", password)
        if "No --server process found" in acknowledgement:
            raise RuntimeError("RustDesk user server is not ready; log in to a desktop session and rerun switch.sh")
        if acknowledgement != "Done!":
            raise RuntimeError("RustDesk did not confirm password setup")
    # Restrict sources and configure authentication before enabling direct access.
    order = {"whitelist": 0, "direct-server": 2}
    for key in sorted(options, key=lambda name: order.get(name, 1)):
        value = options[key]
        if command(binary, "--option", key) != value:
            command(binary, "--option", key, value)
            if command(binary, "--option", key) != value:
                raise RuntimeError("RustDesk did not confirm access settings")
    state_file.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    state_file.write_text(revision)
    state_file.chmod(0o600)



def configure_tailscale(binary, hostname, auth_key_file, tags=()):
    result = subprocess.run(
        [binary, "status", "--json"], capture_output=True, text=True, timeout=15
    )
    status = json.loads(result.stdout)
    state = status.get("BackendState")
    if result.returncode and state != "NeedsLogin":
        raise RuntimeError("Tailscale status failed")
    if state == "NeedsLogin":
        if not auth_key_file or not Path(auth_key_file).is_file():
            raise RuntimeError("Tailscale enrollment requires tailscale-auth-key in the shared secrets")
        credential = Path(auth_key_file).read_text().strip()
        if not credential:
            raise RuntimeError("Tailscale auth key is empty")
        if credential.startswith("tskey-client-") and not tags:
            raise RuntimeError("Tailscale OAuth enrollment requires declared device tags")
        args = [binary, "up", f"--auth-key=file:{auth_key_file}", "--timeout=15s"]
        if hostname:
            args.append(f"--hostname={hostname}")
        if credential.startswith("tskey-client-"):
            args.append("--advertise-tags=" + ",".join(tags))
        result = subprocess.run(args, capture_output=True, timeout=20)
        if result.returncode:
            raise RuntimeError("Tailscale enrollment failed")
        result = subprocess.run(
            [binary, "status", "--json"], capture_output=True, text=True, timeout=15
        )
        if result.returncode or json.loads(result.stdout).get("BackendState") != "Running":
            raise RuntimeError("Tailscale enrollment is not ready")
    elif state == "Running":
        if hostname and status.get("Self", {}).get("HostName") != hostname:
            result = subprocess.run(
                [binary, "set", f"--hostname={hostname}"],
                capture_output=True, timeout=15,
            )
            if result.returncode:
                raise RuntimeError("Tailscale hostname configuration failed")
    elif state != "Stopped":
        raise RuntimeError("Tailscale connection or device approval is pending")
    # Never force a stopped session online or replace an existing account.


def decrypt(encrypted_file, identity):
    env = dict(os.environ, SOPS_AGE_KEY_FILE=str(identity))
    env.pop("SOPS_AGE_KEY", None)
    env.pop("SOPS_AGE_KEY_CMD", None)
    result = subprocess.run(
        [SOPS, "--decrypt", str(encrypted_file)],
        env=env, capture_output=True, text=True, timeout=30,
    )
    if result.returncode:
        raise RuntimeError("Sops decryption failed")
    return json.loads(result.stdout)


def enroll_tailscale(binary, hostname, auth_key, tags, runtime=None):
    # Only the enrollment CLI needs a temporary file. The password stays in memory.
    with tempfile.TemporaryDirectory(prefix="dotfiles-remote-", dir=runtime) as directory:
        auth_file = ""
        if auth_key:
            key_file = Path(directory) / "auth-key"
            key_file.write_text(auth_key)
            key_file.chmod(0o600)
            auth_file = str(key_file)
        configure_tailscale(binary, hostname, auth_file, tags)


def configure_debian(policy_file, encrypted_file, identity):
    secrets = decrypt(encrypted_file, identity)
    policy = json.loads(policy_file.read_text())
    options = policy["rustdesk"]["options"]
    password = secrets.get("rustdesk-password")
    if not isinstance(password, str) or not password:
        raise RuntimeError("RustDesk password is missing")
    configure_rustdesk(RUSTDESK, password, STATE / "rustdesk-state", options)
    enroll_tailscale(
        TAILSCALE, socket.gethostname().split(".")[0].lower(),
        secrets.get("tailscale-auth-key"), policy["tailscale"]["tags"], RUNTIME,
    )


def enroll_darwin(binary, hostname, encrypted_file, identity, policy_file):
    # bootstrap.sh runs this once per Mac; switch never touches the tailnet login.
    if not Path(binary).is_file():
        raise RuntimeError("Tailscale app is not installed; run ./switch.sh, open Tailscale once, then rerun ./bootstrap.sh")
    secrets = decrypt(encrypted_file, identity)
    tags = json.loads(policy_file.read_text())["tailscale"]["tags"]
    enroll_tailscale(binary, hostname, secrets.get("tailscale-auth-key"), tags)


def configure_darwin(user, password_file, policy_file):
    uid = pwd.getpwnam(user).pw_uid
    if os.stat("/dev/console").st_uid != uid:
        raise RuntimeError("The selected macOS user must be logged in")
    binary = "/Applications/RustDesk.app/Contents/MacOS/RustDesk"
    # launchd has just loaded the user's server. Wait at most ten seconds,
    # rather than installing a permanent configuration polling service.
    for _ in range(20):
        server = subprocess.run(
            ["/usr/bin/pgrep", "-u", str(uid), "-f", f"^{binary} --server$"],
            capture_output=True, check=False,
        )
        if server.returncode == 0:
            break
        time.sleep(0.5)
    else:
        raise RuntimeError("RustDesk user server is not ready; log in to the desktop and rerun ./switch.sh")
    options = json.loads(policy_file.read_text())["rustdesk"]["options"]
    configure_rustdesk(binary, password_file.read_text(), Path(f"/var/db/dotfiles-rustdesk/{user}"), options)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    modes = parser.add_subparsers(dest="mode", required=True)
    darwin = modes.add_parser("darwin")
    darwin.add_argument("user")
    darwin.add_argument("password_file", type=Path)
    darwin.add_argument("policy_file", type=Path)
    debian = modes.add_parser("debian")
    debian.add_argument("policy_file", type=Path)
    debian.add_argument("encrypted_file", type=Path)
    debian.add_argument("identity", type=Path)
    enroll = modes.add_parser("enroll")
    enroll.add_argument("binary")
    enroll.add_argument("hostname")
    enroll.add_argument("encrypted_file", type=Path)
    enroll.add_argument("identity", type=Path)
    enroll.add_argument("policy_file", type=Path)
    args = parser.parse_args()
    if args.mode != "enroll" and os.geteuid() != 0:
        raise RuntimeError("Remote-access configuration requires administrator privileges")
    if args.mode == "enroll":
        enroll_darwin(args.binary, args.hostname, args.encrypted_file, args.identity, args.policy_file)
    elif args.mode == "darwin":
        configure_darwin(args.user, args.password_file, args.policy_file)
    else:
        configure_debian(args.policy_file, args.encrypted_file, args.identity)
    print("Remote-access configuration verified.")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
        message = str(error) if isinstance(error, RuntimeError) else "Check apps, identity, and permissions"
        print(f"Remote access not applied: {message}. Secret output suppressed.", file=sys.stderr)
        sys.exit(1)
