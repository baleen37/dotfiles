import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


common = load("remote_access", sys.argv[1])
options = json.loads(Path(sys.argv[2]).read_text())["rustdesk"]["options"]
remote = load("remote", sys.argv[3])


class RemoteAccessTest(unittest.TestCase):
    def test_password_ack_required_before_enabling_direct_access(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            secret = root / "secret"
            secret.write_text("synthetic-password")
            state = root / "state"
            with patch.object(common, "command", return_value="not confirmed") as cli:
                with self.assertRaises(RuntimeError):
                    common.configure_rustdesk(__file__, secret.read_text(), state, options)
                self.assertEqual(cli.call_count, 1)
                self.assertFalse(state.exists())

    def test_repeated_apply_preserves_password_and_restricts_before_listening(self):
        calls, applied_options = [], {}

        def cli(binary, *args):
            calls.append(args)
            if args[0] == "--password":
                return "Done!"
            if len(args) == 3:
                applied_options[args[1]] = args[2]
            return applied_options.get(args[1], "")

        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            secret, state = root / "secret", root / "state"
            secret.write_text("synthetic-password")
            with patch.object(common, "command", side_effect=cli):
                common.configure_rustdesk(__file__, secret.read_text(), state, options)
                self.assertLess(
                    calls.index(("--option", "whitelist", options["whitelist"])),
                    calls.index(("--option", "direct-server", "Y")),
                )
                calls.clear()
                common.configure_rustdesk(__file__, secret.read_text(), state, options)
                self.assertTrue(all(len(args) == 2 for args in calls))
                secret.write_text("rotated-synthetic-password")
                calls.clear()
                common.configure_rustdesk(__file__, secret.read_text(), state, options)
                self.assertEqual(calls[0][0], "--password")

    def test_zero_exit_with_unapplied_option_does_not_record_success(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            secret, state = root / "secret", root / "state"
            secret.write_text("synthetic-password")
            with patch.object(common, "command", side_effect=lambda _, *a: "Done!" if a[0] == "--password" else ""):
                with self.assertRaises(RuntimeError):
                    common.configure_rustdesk(__file__, secret.read_text(), state, options)
                self.assertFalse(state.exists())

    def test_existing_tailnet_never_reenrolls(self):
        status = '{"BackendState":"Running","Self":{"HostName":"macbook-pro"}}'
        with patch.object(common.subprocess, "run", return_value=subprocess.CompletedProcess([], 0, status)) as cli:
            common.configure_tailscale("tailscale", "macbook-pro", "/missing-secret")
            self.assertEqual(cli.call_count, 1)

    def test_enrollment_uses_file_reference_without_key_in_argv(self):
        with tempfile.TemporaryDirectory() as directory:
            secret = Path(directory) / "auth-key"
            secret.write_text("synthetic-auth-key")
            results = [
                subprocess.CompletedProcess([], 1, '{"BackendState":"NeedsLogin"}'),
                subprocess.CompletedProcess([], 0),
                subprocess.CompletedProcess([], 0, '{"BackendState":"Running"}'),
            ]
            with patch.object(common.subprocess, "run", side_effect=results) as cli:
                common.configure_tailscale("tailscale", "vm-test", str(secret))
                argv = cli.call_args_list[1].args[0]
                self.assertIn(f"--auth-key=file:{secret}", argv)
                self.assertNotIn("synthetic-auth-key", repr(argv))

    def test_oauth_enrollment_uses_declared_tags_without_exposing_secret(self):
        with tempfile.TemporaryDirectory() as directory:
            secret = Path(directory) / "oauth"
            secret.write_text("tskey-client-synthetic?ephemeral=false&preauthorized=true")
            results = [subprocess.CompletedProcess([], 1, '{"BackendState":"NeedsLogin"}'), subprocess.CompletedProcess([], 0), subprocess.CompletedProcess([], 0, '{"BackendState":"Running"}')]
            with patch.object(common.subprocess, "run", side_effect=results) as cli:
                common.configure_tailscale("tailscale", "debian", str(secret), ["tag:infra"])
                argv = cli.call_args_list[1].args[0]
                self.assertIn("--advertise-tags=tag:infra", argv)
                self.assertNotIn("tskey-client-synthetic", repr(argv))
            with patch.object(common.subprocess, "run", return_value=results[0]) as cli:
                with self.assertRaises(RuntimeError):
                    common.configure_tailscale("tailscale", "debian", str(secret))
                self.assertEqual(cli.call_count, 1)

    def test_stopped_tailnet_stays_stopped(self):
        with patch.object(common.subprocess, "run", return_value=subprocess.CompletedProcess([], 0, '{"BackendState":"Stopped"}')) as cli:
            common.configure_tailscale("tailscale", "mac", "/missing")
            self.assertEqual(cli.call_count, 1)

    def test_pending_approval_is_not_reported_as_ready(self):
        with patch.object(common.subprocess, "run", return_value=subprocess.CompletedProcess([], 0, '{"BackendState":"NeedsMachineAuth"}')) as cli:
            with self.assertRaises(RuntimeError):
                common.configure_tailscale("tailscale", "mac", "/missing")
            self.assertEqual(cli.call_count, 1)

    def test_unknown_peer_does_not_launch_rustdesk(self):
        with patch.object(remote.Path, "is_file", return_value=True), patch.object(remote.subprocess, "run", return_value=subprocess.CompletedProcess([], 0, '{"BackendState":"Running","Peer":{}}')), patch.object(remote.subprocess, "Popen") as launch, patch.object(sys, "argv", ["dotfiles-remote", "unknown"]):
            with self.assertRaises(ValueError):
                remote.main()
            launch.assert_not_called()


if __name__ == "__main__":
    unittest.main(argv=[sys.argv[0]])
