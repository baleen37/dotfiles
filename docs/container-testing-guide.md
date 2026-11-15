# NixOS VM testing

The files under `tests/containers/` are NixOS **virtual-machine tests**, despite
the historical directory name. They boot isolated test machines; they do not
activate the developer's real host configuration.

## Commands

```bash
nix develop
just check            # Evaluate the entire supported platform matrix
just test             # Execute local unit and integration assertions
just test-containers  # Boot the four NixOS VM suites
```

`just test` does not depend on KVM and never silently becomes evaluation-only.
`just check` does not execute build-time assertions. `just test-all` combines
those two commands; VM execution remains explicit.

`just test-containers` requires Linux and readable and writable `/dev/kvm`.
It fails with an explanation when that requirement is not met, instead of
reporting an evaluation as a successful VM run. CI evaluates all supported
platforms, builds assertions separately, and runs VMs where KVM is usable.

## Suites and discovery

`tests/default.nix` registers the VM suites explicitly and wraps their
configurations with `pkgs.testers.nixosTest`:

| Check                | Source                              | Purpose                                   |
| -------------------- | ----------------------------------- | ----------------------------------------- |
| `container-smoke`    | `tests/containers/smoke-test.nix`   | Essential system and package smoke checks |
| `container-basic`    | `tests/containers/basic-system.nix` | User, SSH and essential packages          |
| `container-services` | `tests/containers/services.nix`     | Service configuration and execution       |
| `container-packages` | `tests/containers/packages.nix`     | Installed tool functionality              |

Unit and integration assertions are discovered automatically from `*-test.nix`
files. The `all-assertions` aggregate excludes VM checks. See
[the test contract](../tests/README.md) for the assertion interface.

VM users are explicit declarations in the fixtures, such as `testuser` in
`basic-system.nix`; changing the shell's `USER` does not select a real deployment
user. Real system users come from the typed registry in `flake-modules/hosts.nix`.
Do not introduce environment-dependent Nix evaluation for test users.

## Adding and diagnosing tests

Add a VM configuration under `tests/containers/` and register it in
`containerTests` in `tests/default.nix`. Add its check to the runner's explicit
VM build list in `scripts/check.sh`. Use the existing fixtures as the starting
point, and assert observable service or command behavior rather than only
configuration text.

For a single existing, tracked check:

```bash
nix build '.#checks.x86_64-linux.container-basic' --no-link --print-build-logs
```

The just runner uses a filtered source snapshot, so new untracked, unignored
files are included without staging. Personal `hosts.local.nix` is excluded from
matrix verification. Report evaluation, assertion execution, and actual VM
boot results separately; a missing builder or unusable KVM is not a passing VM test.
