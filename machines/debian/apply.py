"""Converge Debian remote access from the shared, versioned declaration."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import urllib.request
import zipfile


REPO = Path(__file__).resolve().parents[2]


def run(args, **kwargs):
    result = subprocess.run(args, capture_output=True, text=True, **kwargs)
    if result.returncode:
        raise RuntimeError(f"Command failed: {Path(args[0]).name}")
    return result.stdout.strip()


def root(args):
    return run(args if os.geteuid() == 0 else ["sudo", "--", *args])


def download(asset, destination):
    with urllib.request.urlopen(asset["url"], timeout=60) as response:
        data = response.read()
    if hashlib.sha256(data).hexdigest() != asset["sha256"]:
        raise RuntimeError("Installer checksum mismatch")
    destination.write_bytes(data)


def apply(config, key_file, key_ref):
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
    root(["apt-get", "update"])
    root(["apt-get", "install", "-y", *config["debian"]["packages"]])
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
            root(["apt-get", "install", "-y", str(target)])
        keyring = temp / "tailscale.gpg"
        download(config["debian"]["tailscaleKeyring"], keyring)
        root(["install", "-m", "644", str(keyring), "/usr/share/keyrings/dotfiles-tailscale.gpg"])
        source = temp / "tailscale.list"
        source.write_text(
            "deb [signed-by=/usr/share/keyrings/dotfiles-tailscale.gpg] "
            f"https://pkgs.tailscale.com/stable/debian {codename} main\n"
        )
        root(["install", "-m", "644", str(source), "/etc/apt/sources.list.d/dotfiles-tailscale.list"])
        root(["apt-get", "update"])
        root(["apt-get", "install", "-y", "tailscale"])
        if not key_file.is_file():
            if not shutil.which("op"):
                archive = temp / "op.zip"
                download(assets["op"], archive)
                with zipfile.ZipFile(archive) as zipped:
                    (temp / "op").write_bytes(zipped.read("op"))
                root(["install", "-m", "755", str(temp / "op"), "/usr/local/bin/op"])
            key_file.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
            # A newly-created tempfile is private before 1Password writes it.
            with tempfile.NamedTemporaryFile(dir=key_file.parent, delete=False) as handle:
                restored = Path(handle.name)
            try:
                run(["op", "read", key_ref, "--out-file", str(restored), "--force"])
                run(["age-keygen", "-y", str(restored)])
                restored.replace(key_file)
            finally:
                restored.unlink(missing_ok=True)
    root(["systemctl", "enable", "--now", "tailscaled.service", "rustdesk.service"])
    # This CLI suppresses secrets itself; preserve its actionable diagnostics.
    command = [
        "/usr/bin/python3", str(REPO / "scripts/lib/remote_access.py"), "debian",
        str(REPO / "machines/remote-access.json"),
        str(REPO / "secrets/remote-access.json"), str(key_file.resolve()),
    ]
    result = subprocess.run(command if os.geteuid() == 0 else ["sudo", "--", *command])
    if result.returncode:
        raise RuntimeError("Remote-access configuration failed")
    print("Remote access applied. Device IDs and existing Tailscale sessions were preserved.")


def main():
    config = json.loads((REPO / "machines/remote-access.json").read_text())
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="show the declaration without changing the machine")
    parser.add_argument("--age-key-file", type=Path, default=Path(os.environ.get("SOPS_AGE_KEY_FILE", Path.home() / ".config/sops/age/keys.txt")))
    parser.add_argument("--age-key-ref", default=os.environ.get("DOTFILES_AGE_KEY_REF", config["ageKeyRef"]))
    args = parser.parse_args()
    if args.check:
        print(f"Plan only: Debian 12/13 (amd64, arm64), RustDesk {config['rustdesk']['version']}, Tailscale and sops; one-shot apply, native services at boot.")
        return
    if not args.age_key_ref.startswith("op://"):
        raise RuntimeError("--age-key-ref must be a 1Password reference")
    apply(config, args.age_key_file, args.age_key_ref)


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError):
        raise SystemExit("Remote-access apply failed. Check Debian support, sudo, age identity, and service status; secret output was suppressed.")
