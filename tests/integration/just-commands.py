"""Exercise the public runner using real just and isolated external commands."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

REPO = Path(sys.argv[1]).resolve()


class JustCommands(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.repo = self.root / "repo with spaces"
        self.bin = self.root / "bin"
        self.bin.mkdir()
        for name in ("justfile", "scripts/check.sh", "scripts/cache.sh",
                     "scripts/lib/setup.sh", "scripts/lib/flake-source.sh"):
            target = self.repo / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(REPO / name, target)
        (self.repo / "flake-modules").mkdir()
        (self.repo / ".gitignore").write_text("flake-modules/hosts.local.nix\n")
        (self.repo / "flake-modules/hosts.local.nix").write_text("personal extension")
        subprocess.run(["git", "init", "--quiet", str(self.repo)], check=True)
        subprocess.run(["git", "-C", str(self.repo), "add", "."], check=True)
        (self.repo / "new-module.nix").write_text("new untracked module")
        self.env = dict(os.environ, PATH=f"{self.bin}:{os.environ['PATH']}",
                        FIXTURE=str(self.root), HM_USER="test-linux", FAKE_OS="Linux")
        for name in ("HOME", "XDG_CACHE_HOME", "XDG_CONFIG_HOME", "XDG_STATE_HOME", "XDG_DATA_HOME", "GNUPGHOME"):
            directory = self.root / name.lower()
            directory.mkdir()
            self.env[name] = str(directory)
        self.stub(self.bin / "uname", '''
if [ "${1:-}" = -m ]; then
  if [ "$FAKE_OS" = Darwin ]; then echo arm64; else echo x86_64; fi
else echo "$FAKE_OS"; fi
''')
        self.stub(self.bin / "hostname", 'echo test-host')
        self.stub(self.bin / "sudo", 'echo "unexpected sudo" >&2; exit 99')
        self.stub(self.bin / "nix", '''
printf '%s\\n' "$*" >> "$FIXTURE/nix.log"
for arg in "$@"; do
  case "$arg" in
    path:*)
      src=${arg#path:}; src=${src%%#*}
      test -f "$src/new-module.nix"
      case "$*" in
        *checks.*|*"flake check"*) test ! -e "$src/flake-modules/hosts.local.nix" ;;
      esac
      printf '%s\\n' "$src" > "$FIXTURE/source"
      ;;
  esac
done
[ "${NIX_FAILURE:-0}" = 0 ] || exit "$NIX_FAILURE"
case "$*" in
  *builtins.hasAttr*) echo true ;;
  *home.username*) id -un ;;
  *hostPlatform.system*) echo x86_64-linux ;;
  *"build "*"--json"*) echo '[{"outputs":{"out":"/nix/store/synthetic-closure"}}]' ;;
esac
''')
        self.stub(self.bin / "cachix", '''
cat > "$FIXTURE/uploaded"
exit "${CACHIX_FAILURE:-0}"
''')
        for name in ("bootstrap.sh", "switch.sh"):
            self.stub(self.repo / name, '''
printf '%s\\n' "$*" > "$FIXTURE/activation-request"
exit "${SWITCH_FAILURE:-0}"
''')

    def stub(self, path, body):
        path.write_text(f"#!{shutil.which('bash')}\nset -euo pipefail\n{body}\n")
        path.chmod(0o755)

    def cli(self, *args, success=True):
        result = subprocess.run(["just", *args], cwd=self.repo, env=self.env,
                                capture_output=True, text=True)
        self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)
        source = self.root / "source"
        if source.exists():
            self.assertFalse(Path(source.read_text().strip()).exists(), "snapshot was not cleaned")
        return result

    def test_assertions_run_even_without_vm_support(self):
        for platform in ("Darwin", "Linux"):
            self.env["FAKE_OS"] = platform
            self.cli("test")
        log = (self.root / "nix.log").read_text()
        self.assertIn("checks.aarch64-darwin.all-assertions", log)
        self.assertIn("checks.x86_64-linux.all-assertions", log)
        self.assertNotIn("--no-build", log)
        self.assertNotIn("container-", log)
        self.assertIn("--accept-flake-config", log)

    def test_failures_propagate_on_both_platforms(self):
        self.env["NIX_FAILURE"] = "42"
        for platform in ("Darwin", "Linux"):
            self.env["FAKE_OS"] = platform
            for recipe in ("check", "test", "test-build", "test-all", "fmt-diff", "format"):
                with self.subTest(platform=platform, recipe=recipe):
                    self.cli(recipe, success=False)

    def test_evaluation_is_explicit_and_covers_all_systems(self):
        self.cli("check")
        log = (self.root / "nix.log").read_text()
        self.assertIn("--no-build --all-systems", log)
        self.cli("test-all")
        self.assertIn("all-assertions", (self.root / "nix.log").read_text())

    def test_build_and_switch_delegate_without_reimplementing_contract(self):
        self.cli("build")
        self.assertEqual((self.root / "activation-request").read_text(), "--build\n")
        self.cli("switch")
        self.assertEqual((self.root / "activation-request").read_text(), "\n")
        self.env["SWITCH_FAILURE"] = "23"
        self.cli("switch", success=False)
        self.cli("bootstrap", success=False)
        self.cli("switch", "extra-argument", success=False)

    def test_cache_selects_local_home_or_system_and_accepts_cache_configuration(self):
        for platform, attribute in (("Linux", 'homeConfigurations."test-linux".activationPackage'),
                                    ("Darwin", 'darwinConfigurations."test-host".system')):
            self.env["FAKE_OS"] = platform
            self.cli("cache")
            log = (self.root / "nix.log").read_text()
            self.assertIn(attribute, log)
            self.assertIn("--accept-flake-config", log)
            self.assertEqual((self.root / "uploaded").read_text(), "/nix/store/synthetic-closure\n")
        self.assertFalse((self.root / "activation-request").exists())

    def test_cache_pipeline_propagates_build_and_upload_failures(self):
        self.env["NIX_FAILURE"] = "42"
        self.cli("cache", success=False)
        self.env["NIX_FAILURE"] = "0"
        self.env["CACHIX_FAILURE"] = "24"
        self.cli("cache", success=False)

    def test_default_and_backup_dry_run_do_not_execute_host_actions(self):
        self.cli()
        self.cli("--dry-run", "secrets-backup")
        self.assertFalse((self.repo / "backup.tar.gz").exists())
        self.assertFalse((self.root / "activation-request").exists())
        self.assertFalse((self.root / "nix.log").exists())


if __name__ == "__main__":
    unittest.main(argv=[sys.argv[0]])
