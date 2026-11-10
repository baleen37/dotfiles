"""Drive the Debian CLI with real age/sops and isolated command adapters."""

import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPO = Path(os.environ.get("DOTFILES_TEST_REPO", Path(__file__).resolve().parents[2]))


class DebianStages(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        for name in ("machines/debian", "scripts/lib", "secrets", "bin", "home"):
            (self.root / name).mkdir(parents=True)
        for name in ("machines/debian/apply.py", "machines/debian/apply.sh", "scripts/lib/identity.py"):
            shutil.copy2(REPO / name, self.root / name)
        self.key = self.root / "home/.config/sops/age/keys.txt"
        self.original = self.root / "original"
        subprocess.run(["age-keygen", "-o", str(self.original)], capture_output=True, check=True)
        recipient = subprocess.check_output(["age-keygen", "-y", str(self.original)], text=True).strip()
        encrypted = subprocess.run(
            ["sops", "--encrypt", "--age", recipient, "--input-type", "json", "--output-type", "json", "/dev/stdin"],
            input='{"rustdesk-password":"synthetic-password"}', text=True, capture_output=True, check=True,
        ).stdout
        (self.root / "secrets/remote-access.json").write_text(encrypted)
        config = json.loads((REPO / "machines/remote-access.json").read_text())
        self.policy = self.root / "machines/remote-access.json"
        self.policy.write_text(json.dumps(config))
        self.env = dict(os.environ, HOME=str(self.root / "home"), SOPS_AGE_KEY_FILE=str(self.key),
                        PATH=f"{self.root / 'bin'}:{os.environ['PATH']}", FIXTURE=str(self.root))
        self.stub("dpkg", 'if [ "$1" = --print-architecture ]; then echo amd64; fi')
        self.stub("dpkg-query", 'echo "installed 999.0"')
        self.stub("systemctl", '''
for unit; do :; done
case "$1" in
 show) [ ! -f "$FIXTURE/$unit.state" ] || cat "$FIXTURE/$unit.state" ;;
 disable) echo disabled > "$FIXTURE/$unit.state" ;;
 enable) echo enabled > "$FIXTURE/$unit.state" ;;
 mask) echo masked > "$FIXTURE/$unit.state" ;;
esac
printf 'systemctl %s\\n' "$*" >> "$FIXTURE/calls"
''')
        self.stub("apt-get", '''
[ "$SYSTEMD_OFFLINE" = 1 ]
[ "$DEBIAN_FRONTEND" = noninteractive ]
# Package scripts may enable units even when start/restart is suppressed.
for unit in rustdesk.service tailscaled.service; do echo enabled > "$FIXTURE/$unit.state"; done
printf 'apt-get %s\\n' "$*" >> "$FIXTURE/calls"
[ "${INSTALL_FAILURE:-0}" = 0 ]
''')
        self.stub("sudo", '[ "$1" != -- ] || shift; exec "$@"')
        self.stub("install", 'printf "install %s\\n" "$*" >> "$FIXTURE/calls"')
        self.stub("op", '''
case "$1" in
 --version | whoami) exit 0 ;;
 read)
  while [ "$1" != --out-file ]; do shift; done
  cp "$FIXTURE/original" "$2"
  if [ "${RACE:-0}" = 1 ]; then echo competing > "$SOPS_AGE_KEY_FILE"; fi
  ;;
 *) exit 1 ;;
esac''')
        # Use a synthetic OS declaration while executing the real installer CLI.
        source = self.root / "machines/debian/apply.py"
        (self.root / "os-release").write_text("ID=debian\nVERSION_CODENAME=bookworm\n")
        source.chmod(source.stat().st_mode | 0o200)
        source.write_text(source.read_text().replace('/etc/os-release', str(self.root / 'os-release')))
        (self.root / "scripts/lib/remote_access.py").write_text(
            "import os, pathlib, sys\n"
            "assert sys.argv[1] == 'debian'\n"
            "assert pathlib.Path(sys.argv[-1]).is_file()\n"
            "pathlib.Path(os.environ['FIXTURE'], 'remote-applied').touch()\n"
            "sys.exit(int(os.environ.get('REMOTE_FAILURE', '0')))\n"
        )

    def stub(self, name, body):
        target = self.root / "bin" / name
        target.write_text(f"#!{shutil.which('bash')}\nset -eu\n{body}\n")
        target.chmod(0o755)

    def cli(self, *args, success=True):
        result = subprocess.run(["bash", str(self.root / "machines/debian/apply.sh"), *args],
                                env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)
        return result

    def existing_key(self):
        self.key.parent.mkdir(parents=True)
        shutil.copy2(self.original, self.key)

    def bootstrap(self, success=True):
        # Local fixture download still exercises the real checksum verification.
        config = json.loads(self.policy.read_text())
        keyring = self.root / "keyring"
        keyring.write_bytes(b"synthetic-keyring")
        config["debian"]["tailscaleKeyring"] = {
            "url": keyring.as_uri(), "sha256": hashlib.sha256(keyring.read_bytes()).hexdigest(),
        }
        self.policy.write_text(json.dumps(config))
        return self.cli("bootstrap", success=success)

    def test_build_needs_no_key_and_changes_nothing(self):
        self.cli("switch", "--build")
        self.assertFalse((self.root / "calls").exists())
        self.assertFalse(self.key.exists())
        config = json.loads(self.policy.read_text())
        config["debian"]["assets"]["amd64"]["sops"]["sha256"] = "bad"
        self.policy.write_text(json.dumps(config))
        self.cli("switch", "--build", success=False)

    def test_bootstrap_then_switch_and_repeat_preserve_identity(self):
        self.bootstrap()
        self.assertEqual(self.key.read_bytes(), self.original.read_bytes())
        self.assertEqual(self.key.stat().st_mode & 0o777, 0o600)
        self.assertEqual(list(self.key.parent.iterdir()), [self.key])
        calls = (self.root / "calls").read_text()
        self.assertNotIn("enable --now", calls)
        for unit in ("rustdesk.service", "tailscaled.service"):
            self.assertEqual((self.root / f"{unit}.state").read_text().strip(), "disabled")
        self.assertFalse((self.root / "remote-applied").exists())
        (self.root / "calls").unlink()
        self.cli("switch")
        self.assertTrue((self.root / "remote-applied").exists())
        self.assertNotIn("apt-get", (self.root / "calls").read_text())
        self.bootstrap()
        self.assertEqual(self.key.read_bytes(), self.original.read_bytes())

    def test_missing_or_invalid_key_blocks_switch_without_installation(self):
        self.cli("switch", success=False)
        self.assertFalse((self.root / "calls").exists())
        self.key.parent.mkdir(parents=True)
        self.key.write_text("invalid")
        self.cli("switch", success=False)
        self.bootstrap(success=False)
        self.assertEqual(self.key.read_text(), "invalid")
        self.assertFalse((self.root / "remote-applied").exists())

    def test_bootstrap_preserves_enabled_services(self):
        self.existing_key()
        for unit in ("rustdesk.service", "tailscaled.service"):
            (self.root / f"{unit}.state").write_text("enabled\n")
        self.bootstrap()
        for unit in ("rustdesk.service", "tailscaled.service"):
            self.assertEqual((self.root / f"{unit}.state").read_text().strip(), "enabled")

    def test_failed_install_restores_startup_policy(self):
        self.existing_key()
        self.env["INSTALL_FAILURE"] = "1"
        self.bootstrap(success=False)
        for unit in ("rustdesk.service", "tailscaled.service"):
            self.assertEqual((self.root / f"{unit}.state").read_text().strip(), "disabled")
        self.assertEqual(self.key.read_bytes(), self.original.read_bytes())

    def test_symlink_and_racing_destination_are_preserved(self):
        self.key.parent.mkdir(parents=True)
        self.key.symlink_to(self.original)
        self.bootstrap(success=False)
        self.assertTrue(self.key.is_symlink())
        self.key.unlink()
        self.env["RACE"] = "1"
        result = self.bootstrap(success=False)
        self.assertIn("destination now exists", result.stderr)
        self.assertEqual(self.key.read_text(), "competing\n")
        self.assertEqual(list(self.key.parent.iterdir()), [self.key])

    def test_remote_failure_is_propagated_and_old_options_are_rejected(self):
        self.existing_key()
        self.env["REMOTE_FAILURE"] = "23"
        self.cli("switch", success=False)
        for arguments in (("--check",), ("switch", "--age-key-file", str(self.key)), ("bootstrap", "--build")):
            self.cli(*arguments, success=False)


if __name__ == "__main__":
    unittest.main()
