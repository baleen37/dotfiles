# Tests

Every check is a Nix derivation that builds if an assertion holds and fails if it
does not. There is no test runner: `nix flake check` builds them.

```bash
make test            # evaluate all checks; build them where the platform allows
make test-build      # build every unit + integration assertion (any platform)
make test-containers # NixOS VM tests; needs Linux + /dev/kvm
```

> **`make test` does not necessarily run assertions.** Container tests need Linux
> and `/dev/kvm`, so without them `make test` falls back to
> `nix flake check --no-build`, which only _evaluates_ checks. A false assertion
> produces a derivation that is never built, and therefore never fails. Use
> `make test-build` to actually run them.

Run one check directly:

```bash
nix build '.#checks.aarch64-darwin.unit-darwin-sudo'
nix build '.#checks.x86_64-linux.integration-home-manager'
```

## Layout

```text
tests/
├── default.nix             # discovery -> flake checks
├── unit/*-test.nix         # one module or library, evaluated in isolation
├── integration/*-test.nix  # configurations evaluated against each other
├── containers/*.nix        # NixOS VM tests (Linux + KVM), wired up explicitly
└── lib/                    # shared assertions and fixtures
```

`unit/` and `integration/` are discovered automatically: add
`<feature>-test.nix` and it becomes `checks.<system>.unit-<feature>` or
`checks.<system>.integration-<feature>`. Subdirectories are discovered too, with
the directory name folded into the check name.

## Writing a test

A test file is a function of `{ inputs, system, pkgs, lib, self, ... }` that
evaluates to one of:

- a derivation — one check;
- an attribute set of derivations — one check per attribute, named
  `<test>-<attribute>`;
- `{ platforms = [ ... ]; value = <either of the above>; }` — as above, but
  skipped entirely when `platforms` excludes the current system.

`platforms` accepts `"any"`, `"darwin"` and `"linux"`. A file with no `platforms`
attribute runs everywhere.

```nix
{ pkgs, lib, self, ... }:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
in
{
  platforms = [ "darwin" ];
  value = helpers.testSuite "my-feature" [
    (helpers.assertTest "some-invariant" someCondition
      "why this matters, and what breaks when it does not hold"
    )
  ];
}
```

Assertion names become store path names, so slug anything containing `*`, `/` or
other illegal characters before interpolating it into a test name.

## Helpers

`lib/test-helpers.nix` — the two primitives everything is built from:

| Function                            | Purpose                                   |
| ----------------------------------- | ----------------------------------------- |
| `assertTest name condition message` | Fails the build when `condition` is false |
| `testSuite name tests`              | Aggregates assertions into a single check |

`lib/common-assertions.nix` — assertions that generate their own failure text.
Each takes a trailing `message`; pass `null` for the generated one:
`assertCondition`, `assertAttrExists`, `assertAttrPathExists`,
`assertAttrEquals`, `assertListContains`, `assertListNotEmpty`, `assertNotNull`.

Domain helpers: `lib/darwin-test-helpers.nix` (grouped `system.defaults`
assertions), `lib/starship-test-helpers.nix`, `lib/plugin-test-helpers.nix`
(vim/tmux plugin and config-text predicates).

Fixtures: `lib/mock-config.nix` (a minimal `config` argument for modules imported
outside the module system), `lib/constants.nix` (values shared between a module
and the test asserting it), `lib/fixtures/common-packages.nix`.

## What belongs in a test

The suite exists to catch changes that break silently. Before adding a check, ask
what failure it would have caught.

Worth asserting:

- a value that must agree in two places — `lib/cache-config.nix` versus
  `flake.nix` and the CI workflow, or `lib/user-info.nix` versus `programs.git`;
- something that evaluates fine but never runs, such as a
  `system.activationScripts` segment nix-darwin does not splice in;
- a setting whose loss you would not notice until much later, such as
  `pull.rebase` or a missing `stateVersion`;
- forcing a configuration to evaluate at all — reaching into `.config` expands
  the whole module tree, so a broken machine file fails here instead of during
  `make switch`.

Not worth asserting:

- values defined inside the test itself. `let xs = [ "a" ]; in builtins.elem "a" xs`
  passes forever and covers nothing;
- that a helper is a function, or that an attribute the test just wrote exists;
- restating a literal from the source. `user-info.email == "..."` only asserts
  that someone copied the string twice;
- `tryEval` on a lazy attribute set — it succeeds without evaluating anything
  meaningful, so `result.success` is close to always true;
- the test framework itself.
