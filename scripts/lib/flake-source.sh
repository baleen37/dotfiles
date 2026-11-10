#!/usr/bin/env bash
# Own the filtered source used for evaluation, builds and activation.
cleanup_flake() {
  [ -z "${SOURCE_DIR:-}" ] || rm -rf "$SOURCE_DIR"
}
prepare_flake() {
  local file source destination
  if [ -z "${SOURCE_DIR:-}" ]; then
    git rev-parse --show-toplevel > /dev/null 2>&1 || die 'a Git checkout is required to safely select flake files'
    # Resolve symlinks: macOS /tmp -> private/tmp, and Nix rejects a path:
    # flake whose path goes through a symlink.
    SOURCE_DIR=$(cd "$(mktemp -d /tmp/dotfiles-source.XXXXXX)" && pwd -P)
    trap cleanup_flake EXIT
    source="$SOURCE_DIR/source"
    mkdir "$source"
    # Enumerate before copying: a Git failure must never produce a partial source.
    git ls-files -z --cached --others --exclude-standard > "$SOURCE_DIR/files" || die 'cannot select flake files'
    while IFS= read -r -d '' file; do
      [ -e "$file" ] || [ -L "$file" ] || continue
      destination="$source/$file"
      [ -d "${destination%/*}" ] || mkdir -p "${destination%/*}"
      # Preserve symlinks; following one could copy an ignored private target.
      cp -Pp "./$file" "$destination"
    done < "$SOURCE_DIR/files"
  fi
  source="$SOURCE_DIR/source"
  # The only intentionally ignored input. Never admit other ignored files.
  file=flake-modules/hosts.local.nix
  if [ -e "$file" ] || [ -L "$file" ]; then
    [ -f "$file" ] && [ ! -L "$file" ] || die 'local host registry must be a regular file'
    mkdir -p "$source/flake-modules"
    cp -p "$file" "$source/$file"
  fi
  # Public result consumed by bootstrap.sh, switch.sh and setup.sh.
  # shellcheck disable=SC2034
  FLAKE_REF="path:$source"
}
activate_darwin() (
  # Keep the exact sudoers command while resolving . to the checked snapshot.
  cd "$SOURCE_DIR/source" || die 'cannot enter prepared source'
  sudo -H /run/current-system/sw/bin/darwin-rebuild switch --flake ".#$HOST"
)
