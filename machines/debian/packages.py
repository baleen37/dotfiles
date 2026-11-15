"""Native Debian packages, verified downloads, and service startup preservation."""

from contextlib import contextmanager
import hashlib
from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import urllib.request
import zipfile


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
