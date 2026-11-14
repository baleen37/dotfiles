import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch


REPO = Path(sys.argv[1]).resolve()


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


installer = load("installer", REPO / "machines/debian/apply.py")
driver = load("driver", REPO / "scripts/lib/remote_access.py")


class DebianRemoteAccessTest(unittest.TestCase):
    def test_download_reads_in_bounded_chunks(self):
        payload = b"x" * (2 * 1024 * 1024) + b"last chunk"

        class BoundedResponse(io.BytesIO):
            def read(self, size=-1):
                if not 0 < size <= 1024 * 1024:
                    raise AssertionError("download must read at most 1 MiB at a time")
                return super().read(size)

        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / "installer"
            asset = {"url": "https://example.invalid/installer", "sha256": hashlib.sha256(payload).hexdigest()}
            with patch.object(installer.urllib.request, "urlopen", return_value=BoundedResponse(payload)):
                installer.download(asset, target)
            self.assertEqual(target.read_bytes(), payload)

    def test_checksum_failure_preserves_existing_file(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source, target = root / "source", root / "target"
            source.write_text("untrusted-installer")
            target.write_text("existing-binary")
            target.chmod(0o640)
            with self.assertRaises(RuntimeError):
                installer.download({"url": source.as_uri(), "sha256": "0" * 64}, target)
            self.assertEqual(target.read_text(), "existing-binary")
            digest = hashlib.sha256(source.read_bytes()).hexdigest()
            installer.download({"url": source.as_uri(), "sha256": digest}, target)
            self.assertEqual(target.read_bytes(), source.read_bytes())
            self.assertEqual(target.stat().st_mode & 0o777, 0o640)

    def test_decryption_to_service_commands_repeat_apply_and_failure(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            state, runtime = root / "state", root / "run"
            state.mkdir(mode=0o700)
            runtime.mkdir(mode=0o700)
            shutil.copy2(REPO / "machines/remote-access.json", root / "configuration.json")
            identity = state / "age-key.txt"
            subprocess.run(["age-keygen", "-o", str(identity)], capture_output=True, check=True)
            recipient = subprocess.check_output(["age-keygen", "-y", str(identity)], text=True).strip()
            encrypted = subprocess.run(
                ["sops", "--encrypt", "--age", recipient, "--input-type", "json", "--output-type", "json", "/dev/stdin"],
                input=json.dumps({"rustdesk-password": "synthetic-password"}),
                text=True, capture_output=True, check=True,
            ).stdout
            (root / "secrets.json").write_text(encrypted)
            binary = root / "rustdesk"
            binary.write_text(f"#!{sys.executable}\n" + '''
import json, os, pathlib, sys
p = pathlib.Path(__file__).with_suffix('.json')
s = json.loads(p.read_text()) if p.exists() else {'passwordCalls': 0, 'options': {}}
a = sys.argv[1:]
if a[0] == '--password':
    if os.environ.get('REJECT_PASSWORD'):
        print('rejected')
        sys.exit(0)
    s['passwordCalls'] += 1
    print('Done!')
elif a[0] == '--option':
    if len(a) == 3: s['options'][a[1]] = a[2]
    print(s['options'].get(a[1], ''))
p.write_text(json.dumps(s))
''')
            binary.chmod(0o700)
            tailscale = root / "tailscale"
            tailscale.write_text(f"#!{sys.executable}\n" + '''
import json, sys
assert sys.argv[1:] == ['status', '--json'], 'Existing session must not be re-enrolled'
print(json.dumps({'BackendState': 'Running', 'Self': {'HostName': 'debian-test'}}))
''')
            tailscale.chmod(0o700)
            with patch.multiple(driver, STATE=state, RUNTIME=runtime, SOPS=shutil.which("sops"), RUSTDESK=str(binary), TAILSCALE=str(tailscale)), patch.object(driver.socket, "gethostname", return_value="debian-test"):
                driver.configure_debian(root / "configuration.json", root / "secrets.json", identity)
                driver.configure_debian(root / "configuration.json", root / "secrets.json", identity)
                # The tailscale double fails on anything but a status query.
                driver.enroll_debian(root / "configuration.json", root / "secrets.json", identity)
                applied = json.loads(binary.with_suffix(".json").read_text())
                self.assertEqual(applied["passwordCalls"], 1)
                self.assertEqual(applied["options"]["direct-server"], "Y")
                self.assertEqual(list(runtime.iterdir()), [])
                stamp = (state / "rustdesk-state").read_text()
                # A new binary requires reconfirmation; exit 0 with a rejection
                # must neither update the success stamp nor leave plaintext files.
                binary.touch()
                with patch.dict(os.environ, {"REJECT_PASSWORD": "1"}):
                    with self.assertRaises(RuntimeError):
                        driver.configure_debian(root / "configuration.json", root / "secrets.json", identity)
                self.assertEqual((state / "rustdesk-state").read_text(), stamp)
                self.assertEqual(list(runtime.iterdir()), [])
                identity.write_text("invalid-synthetic-identity")
                with self.assertRaises(RuntimeError):
                    driver.configure_debian(root / "configuration.json", root / "secrets.json", identity)
                self.assertEqual(list(runtime.iterdir()), [])


if __name__ == "__main__":
    unittest.main(argv=[sys.argv[0]])
