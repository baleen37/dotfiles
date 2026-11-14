"""Converge Debian remote access from the shared, versioned declaration."""

import argparse
from contextlib import contextmanager
import getpass
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import signal
import sys
import tempfile
import time
import urllib.request
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts/lib"))
import identity


REPO = Path(__file__).resolve().parents[2]


def run(args, **kwargs):
    result = subprocess.run(args, capture_output=True, text=True, **kwargs)
    if result.returncode:
        raise RuntimeError(f"Command failed: {Path(args[0]).name}")
    return result.stdout.strip()


def root(args):
    return run(args if os.geteuid() == 0 else ["sudo", "--", *args])


def apt(*args):
    # Maintainer scripts must not start, stop or restart existing sessions.
    return root(["env", "SYSTEMD_OFFLINE=1", "DEBIAN_FRONTEND=noninteractive", "apt-get", *args])


@contextmanager
def preserve_service_startup():
    units = ("rustdesk.service", "tailscaled.service")
    restore = {
        "": ["disable"],
        "disabled": ["disable"],
        "enabled": ["enable"],
        "enabled-runtime": ["enable", "--runtime"],
        "masked": ["mask", "--force"],
        "masked-runtime": ["mask", "--force", "--runtime"],
    }
    states = {unit: run(["systemctl", "show", "--property=UnitFileState", "--value", unit]) for unit in units}
    if any(state not in restore for state in states.values()):
        raise RuntimeError("Unsupported remote-service startup state; no installation started")
    try:
        yield
    finally:
        root(["systemctl", "daemon-reload"])
        for unit, previous in states.items():
            current = run(["systemctl", "show", "--property=UnitFileState", "--value", unit])
            if not current or current == previous:
                continue
            # Packages may enable units even when SYSTEMD_OFFLINE suppresses start.
            root(["systemctl", "disable", unit])
            if previous not in ("", "disabled"):
                root(["systemctl", *restore[previous], unit])


def download(asset, destination):
    digest = hashlib.sha256()
    with tempfile.TemporaryFile() as staged:
        with urllib.request.urlopen(asset["url"], timeout=60) as response:
            while chunk := response.read(1024 * 1024):
                digest.update(chunk)
                staged.write(chunk)
        if digest.hexdigest() != asset["sha256"]:
            raise RuntimeError("Installer checksum mismatch")
        # Preserve the destination until verification succeeds, including its mode.
        staged.seek(0)
        with destination.open("wb") as target:
            shutil.copyfileobj(staged, target)


def install(config, key_file):
    release = dict(
        line.split("=", 1) for line in Path("/etc/os-release").read_text().splitlines()
        if "=" in line
    )
    codename = release.get("VERSION_CODENAME", "").strip('"')
    if release.get("ID", "").strip('"') != "debian" or codename not in {"bookworm", "trixie"}:
        raise RuntimeError("Supported targets: Debian 12/13 with systemd")
    arch = run(["dpkg", "--print-architecture"])
    if arch not in config["debian"]["assets"]:
        raise RuntimeError("Supported architectures: amd64, arm64")
    run(["systemctl", "show-environment"])
    apt("update")
    apt("install", "-y", *config["debian"]["packages"])
    with tempfile.TemporaryDirectory(prefix="dotfiles-remote-") as directory:
        temp = Path(directory)
        assets = config["debian"]["assets"][arch]
        versions = {"sops": config["debian"]["sopsVersion"], "rustdesk": config["rustdesk"]["version"]}
        for package, requested in versions.items():
            installed = subprocess.run(
                ["dpkg-query", "-W", "-f=${db:Status-Status} ${Version}", package],
                capture_output=True, text=True,
            )
            status, _, current = installed.stdout.strip().partition(" ")
            if installed.returncode == 0 and status == "installed" and subprocess.run(
                ["dpkg", "--compare-versions", current, "ge", requested],
                capture_output=True,
            ).returncode == 0:
                continue
            target = temp / f"{package}.deb"
            download(assets[package], target)
            apt("install", "-y", str(target))
        keyring = temp / "tailscale.gpg"
        download(config["debian"]["tailscaleKeyring"], keyring)
        root(["install", "-m", "644", str(keyring), "/usr/share/keyrings/dotfiles-tailscale.gpg"])
        source = temp / "tailscale.list"
        source.write_text(
            "deb [signed-by=/usr/share/keyrings/dotfiles-tailscale.gpg] "
            f"https://pkgs.tailscale.com/stable/debian {codename} main\n"
        )
        root(["install", "-m", "644", str(source), "/etc/apt/sources.list.d/dotfiles-tailscale.list"])
        apt("update")
        apt("install", "-y", "tailscale")
        if not key_file.exists() and not key_file.is_symlink() and not shutil.which("op"):
            archive = temp / "op.zip"
            download(assets["op"], archive)
            with zipfile.ZipFile(archive) as zipped:
                (temp / "op").write_bytes(zipped.read("op"))
            root(["install", "-m", "755", str(temp / "op"), "/usr/local/bin/op"])


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


def apply(key_file):
    identity.check(key_file, check_secrets)
    root(["systemctl", "enable", "--now", "tailscaled.service", "rustdesk.service"])
    remote_access("debian", key_file, "Remote-access configuration failed")
    print("Remote access applied. Device IDs and existing Tailscale sessions were preserved.")
    sync_wiki()


def sync_wiki():
    # Share ~/wiki with the always-on hub only; other devices reach this one through it.
    hub = json.loads((REPO / "machines/syncthing.json").read_text())["hub"]
    if not shutil.which("syncthing"):
        raise RuntimeError("Syncthing is missing: run ./bootstrap.sh")
    root(["systemctl", "enable", "--now", f"syncthing@{getpass.getuser()}.service"])
    for _ in range(30):
        if subprocess.run(["syncthing", "cli", "show", "system"], capture_output=True).returncode == 0:
            break
        time.sleep(1)
    else:
        raise RuntimeError("Syncthing did not start")

    def config(*args):
        return run(["syncthing", "cli", "config", *args])

    for name, device in hub.items():
        if device not in config("devices", "list").split():
            config("devices", "add", "--device-id", device, "--name", name)
    wiki = str(Path.home() / "wiki")
    if "wiki" not in config("folders", "list").split():
        config("folders", "add", "--id", "wiki", "--label", "wiki", "--path", wiki)
    elif config("folders", "wiki", "path", "get") != wiki:
        # Sharing a folder that points elsewhere would sync the wrong directory.
        raise RuntimeError(f"Syncthing folder 'wiki' does not point to {wiki}")
    for device in hub.values():
        if device not in config("folders", "wiki", "devices", "list").split():
            config("folders", "wiki", "devices", "add", "--device-id", device)
    device_id = json.loads(run(["syncthing", "cli", "show", "system"]))["myID"]
    print(f"~/wiki shared with the Syncthing hub. Add this device there: {device_id}")


def main():
    config = json.loads((REPO / "machines/remote-access.json").read_text())
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=["bootstrap", "switch"])
    parser.add_argument("--build", action="store_true")
    args = parser.parse_args()
    key_file = Path(os.environ.get("SOPS_AGE_KEY_FILE", Path.home() / ".config/sops/age/keys.txt"))
    if args.mode == "bootstrap" and args.build:
        parser.error("Usage: apply.sh bootstrap | switch [--build]")
    if args.build:
        validate_declaration(config)
        print(f"Declaration valid: Debian 12/13 (amd64, arm64), RustDesk {config['rustdesk']['version']}, Tailscale and sops; no changes made.")
        return
    if args.mode == "bootstrap":
        key_ref = os.environ.get("DOTFILES_AGE_KEY_REF", config["ageKeyRef"])
        if not key_ref.startswith("op://"):
            raise RuntimeError("DOTFILES_AGE_KEY_REF must be a 1Password reference")
        bootstrap(config, key_file, key_ref)
    else:
        apply(key_file)


def validate_declaration(config):
    downloads = [
        asset for arch in ("amd64", "arm64")
        for asset in config["debian"]["assets"][arch].values()
    ] + [config["debian"]["tailscaleKeyring"]]
    for asset in downloads:
        if not asset["url"].startswith("https://") or len(asset["sha256"]) != 64:
            raise RuntimeError("Invalid download declaration")
        int(asset["sha256"], 16)
    if not config["rustdesk"]["options"] or not config["debian"]["packages"]:
        raise RuntimeError("Empty remote-access declaration")


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
