"""Debian stage and identity regressions; no packages or real secrets used."""

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

    def test_invalid_destinations_stop_before_commands(self):
        for kind in ("missing", "empty", "directory", "dangling", "symlink"):
            with self.subTest(kind=kind):
                key = self.key.parent / kind
                if kind == "empty":
                    key.touch()
                elif kind == "directory":
                    key.mkdir()
                elif kind in ("dangling", "symlink"):
                    target = self.key.parent / "target"
                    if kind == "symlink":
                        target.write_text("synthetic identity")
                    key.symlink_to(target)
                with patch.object(APPLY, "run") as run:
                    with self.assertRaises(RuntimeError):
                        APPLY.validate_identity(key)
                    run.assert_not_called()

    def test_failed_preflight_does_not_start_services(self):
        self.key.write_text("synthetic identity")
        with patch.object(APPLY, "run", side_effect=["public", RuntimeError("decrypt")]), patch.object(APPLY, "root") as root:
            with self.assertRaises(RuntimeError):
                APPLY.switch(self.key)
            root.assert_not_called()

    def test_switch_only_validates_and_applies(self):
        self.key.write_text("synthetic identity")
        events = []
        with patch.object(APPLY, "run", side_effect=lambda args, **kw: events.append(args) or ""), patch.object(APPLY, "root", side_effect=lambda args: events.append(args)), patch.object(APPLY.subprocess, "run", return_value=subprocess.CompletedProcess([], 0)) as remote:
            APPLY.switch(self.key)
        self.assertEqual([args[0] for args in events], ["age-keygen", "sops", "systemctl"])
        self.assertTrue(any("remote_access.py" in arg for arg in remote.call_args.args[0]))

    def bootstrap_with(self, existing=False, race=False, decrypt_failure=False):
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
                if race:
                    self.key.write_text("competing identity")
            if args[0] == "sops" and decrypt_failure:
                raise RuntimeError("synthetic decryption failure")
            return ""

        original_read = Path.read_text

        def read_text(path, *args, **kwargs):
            if path == Path("/etc/os-release"):
                return "ID=debian\nVERSION_CODENAME=bookworm\n"
            return original_read(path, *args, **kwargs)

        with patch.object(Path, "read_text", read_text), patch.object(APPLY, "run", side_effect=run), patch.object(APPLY, "root", side_effect=lambda args: commands.append(args)), patch.object(APPLY, "download", side_effect=lambda asset, path: path.write_bytes(b"fixture")), patch.object(APPLY.shutil, "which", return_value="/fake/op"), patch.object(APPLY.subprocess, "run", return_value=subprocess.CompletedProcess([], 0, "installed 1")):
            APPLY.bootstrap(config, self.key, "op://fixture/key/value")
        return commands

    def test_bootstrap_preserves_existing_identity_without_op(self):
        commands = self.bootstrap_with(existing=True)
        self.assertEqual(self.key.read_text(), "existing synthetic identity")
        self.assertEqual(self.key.stat().st_mode & 0o777, 0o600)
        self.assertFalse(any(args[0] == "op" for args in commands))
        self.assertFalse(any(args[:2] == ["systemctl", "enable"] for args in commands))

    def test_restored_identity_permissions_and_no_overwrite(self):
        self.bootstrap_with()
        self.assertEqual(self.key.stat().st_mode & 0o777, 0o600)
        self.assertEqual(self.key.parent.stat().st_mode & 0o777, 0o700)
        self.key.unlink()
        with self.assertRaises(FileExistsError):
            self.bootstrap_with(race=True)
        self.assertEqual(self.key.read_text(), "competing identity")
        self.assertEqual(list(self.key.parent.iterdir()), [self.key])

    def test_failed_restoration_does_not_publish_key(self):
        with self.assertRaises(RuntimeError):
            self.bootstrap_with(decrypt_failure=True)
        self.assertFalse(self.key.exists())
        self.assertEqual(list(self.key.parent.iterdir()), [])


if __name__ == "__main__":
    unittest.main()
