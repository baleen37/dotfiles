# The script keeps the work-host sudoers command exact; make only delegates.
{ pkgs, ... }:
pkgs.runCommand "switch-command-contract" { nativeBuildInputs = [ pkgs.gnugrep ]; } ''
  grep -qF './switch.sh "$(NIXNAME)"' ${../../Makefile}
  grep -qF 'HM_USER="$(HM_USER)" ./switch.sh --home' ${../../Makefile}
  grep -qF 'sudo -H /run/current-system/sw/bin/darwin-rebuild switch --flake "$darwin_ref#$HOST"' ${../../switch.sh}
  grep -qF 'nohup sudo -n -H /run/current-system/sw/bin/nh clean all --keep 3' ${../../switch.sh}
  grep -qF 'switch --sudo --flake "$FLAKE_REF#$HOST"' ${../../switch.sh}
  touch "$out"
''
