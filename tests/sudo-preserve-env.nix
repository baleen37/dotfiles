{ pkgs }:
pkgs.runCommand "sudo-preserve-env-test" {} ''
  grep -q -- "sudo --preserve-env=USER" ${../apps/x86_64-linux/build-switch}
  grep -q -- "sudo --preserve-env=USER" ${../apps/x86_64-darwin/build-switch}
  grep -q -- "sudo --preserve-env=USER" ${../apps/aarch64-darwin/build-switch}
  grep -q -- "--preserve-env=USER" ${../Makefile}
  touch $out
''
