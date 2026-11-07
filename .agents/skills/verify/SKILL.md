---
name: verify
description: Verify dotfiles host selection through the Nix CLI without activating a system.
---

Use an isolated copy containing tracked and unignored files (`git ls-files -co --exclude-standard`). Skip deleted files and preserve relative paths. Use `path:/absolute/copy` so new machine modules participate before staging. Keep the user's ignored `flake-modules/hosts.local.nix` out of this copy: the host-list checks expect the tracked registry.

For a minimal-host probe, add `flake-modules/hosts.local.nix` only to the copy, registering a Darwin host with `machineModules = [ ../machines/darwin/common.nix ];`. Run `nix eval path:/absolute/copy#darwinConfigurations.<probe>.config --json --apply 'c: { casks = c.homebrew.casks; masApps = c.homebrew.masApps; packages = map (p: p.pname or p.name) c.home-manager.users.<user>.home.packages; activation = builtins.attrNames c.home-manager.users.<user>.home.activation; }'`. Expect no GUI apps, optional development packages or personal activation hooks. Also evaluate `darwinConfigurations.<probe>.system.drvPath` to force system assembly.

Probe a selected feature in one machine and inspect another output through `nix eval`; changes must stay local. Remove the temporary registry before checking the tracked host matrix.

For migration comparisons, capture package store paths, casks, brews, taps, MAS apps, selected defaults, sudo rules and Home Manager activation derivations before and after. Compare package sets rather than ordering. Source root hashes can change when copying the repository; compare the referenced file content.

System activation and app deletion are outside this verification flow. Linux VM execution requires a Linux builder with KVM; report unavailable builders explicitly.

For bootstrap changes, drive `bootstrap.sh` and `switch.sh` separately. Use `switch.sh --build` for a real configuration build without activation. Use synthetic identities and external-command doubles for 1Password failures; never print or copy the real identity while testing. The CLI scenarios live in `tests/integration/setup-scripts.sh`.

For actual Home Manager activation in a synthetic home, explicitly set `HOME`, `XDG_STATE_HOME`, `XDG_DATA_HOME`, `XDG_CONFIG_HOME`, `XDG_CACHE_HOME` and `GNUPGHOME` to that fixture. Merely setting HOME is insufficient: inherited XDG paths can update the real Home Manager profile and GC root. Set the SOPS runtime mount directory inside the fixture and disable login-agent loading. Check decryption, SSH key parsing, GPG import and original profile-root preservation.
