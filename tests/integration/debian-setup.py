"""Debian installer regressions; no packages or real secrets used."""

import importlib.util
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch


SOURCE = Path(os.environ.get("DOTFILES_TEST_REPO", Path(__file__).resolve().parents[2])) / "machines/debian/apply.py"
SPEC = importlib.util.spec_from_file_location("debian_apply", SOURCE)
APPLY = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(APPLY)


class DebianStages(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.key = Path(self.directory.name) / "age" / "keys.txt"
        self.key.parent.mkdir()

    def apply_with(self, existing=False, remote_failure=False):
        if existing:
            self.key.write_text("existing synthetic identity")
        config = {
            "debian": {"assets": {"amd64": {}}, "packages": [], "sopsVersion": "1", "tailscaleKeyring": {}},
            "rustdesk": {"version": "1"},
        }
        commands = []

        def run(args, **kwargs):
            commands.append(args)
            if args[0] == "dpkg":
                return "amd64"
            if args[0] == "op":
                Path(args[args.index("--out-file") + 1]).write_text("restored synthetic identity")
            return ""

        original_read = Path.read_text

        def read_text(path, *args, **kwargs):
            if path == Path("/etc/os-release"):
                return "ID=debian\nVERSION_CODENAME=bookworm\n"
            return original_read(path, *args, **kwargs)

        with patch.object(Path, "read_text", read_text), patch.object(APPLY, "run", side_effect=run), patch.object(APPLY, "root", side_effect=lambda args: commands.append(args)), patch.object(APPLY, "download", side_effect=lambda asset, path: path.write_bytes(b"fixture")), patch.object(APPLY.shutil, "which", return_value="/fake/op"), patch.object(APPLY.subprocess, "run", side_effect=lambda args, **kw: subprocess.CompletedProcess(args, 1 if remote_failure and any("remote_access.py" in arg for arg in args) else 0, "installed 1")):
            APPLY.apply(config, self.key, "op://fixture/key/value")
        return commands

    def test_apply_preserves_existing_identity_and_installed_versions(self):
        commands = self.apply_with(existing=True)
        self.assertEqual(self.key.read_text(), "existing synthetic identity")
        self.assertFalse(any(args[0] == "op" for args in commands))
        self.assertFalse(any(args[0] == "apt-get" and args[-1].endswith(".deb") for args in commands))
        self.assertIn(["systemctl", "enable", "--now", "tailscaled.service", "rustdesk.service"], commands)

    def test_restore_keeps_private_file_and_removes_temporary_identity(self):
        self.apply_with()
        self.assertEqual(self.key.read_text(), "restored synthetic identity")
        self.assertEqual(self.key.stat().st_mode & 0o777, 0o600)
        self.assertEqual(list(self.key.parent.iterdir()), [self.key])

    def test_remote_configuration_failure_is_propagated(self):
        with self.assertRaisesRegex(RuntimeError, "Remote-access configuration failed"):
            self.apply_with(existing=True, remote_failure=True)


if __name__ == "__main__":
    unittest.main()
