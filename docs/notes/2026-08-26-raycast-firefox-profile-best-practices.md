# Raycast Firefox Profile Chooser Best Practices

Date: 2026-08-26

Scope: `users/shared/programs/.config/raycast/extensions/firefox-profile/`, the Firefox launcher and Script Command, and the Home Manager module in `users/shared/programs/raycast.nix`.

## Decision

Keep the native Raycast list as the normal profile-switching interface. Remove Firefox Profile Manager from that flow. Profile Manager is an administrative UI: Mozilla documents starting it while Firefox is closed, and selecting a profile there can make it the default for the next startup. That is a poor fit for a quick launcher and can introduce an unwanted default-profile change. See [Mozilla's Profile Manager documentation](https://support.mozilla.org/en-US/kb/profile-manager-create-remove-switch-firefox-profiles?style_mode=inproduct).

## Findings

### MUST

1. Pass a stable profile identity to the launcher.

   `src/choose-profile.tsx:140-150` currently passes the display name to the shell launcher. Display names are presentation data and can be duplicated or renamed. The list already has the resolved profile path, so the action should pass that path, or a stable profile identifier that the launcher resolves. This is an inference from the current two-stage lookup, not a Firefox API guarantee.

2. Detach a newly launched Firefox process.

   `firefox-profile-launcher.zsh:244-246` runs Firefox in the foreground. A Raycast action invoking the Script Command can remain pending for the lifetime of a newly created Firefox process. Use a clearly owned non-blocking launch path, with stdout and stderr redirected, while retaining the existing-process focus path. Node's [`execFile` documentation](https://nodejs.org/api/child_process.html) confirms that the executable is spawned directly and that the promisified call resolves when the child process terminates. The current `execFileAsync` call is appropriate for the short launcher operation, but the shell launcher must not wait on the long-lived browser process.

3. Stop using the deprecated focus-stealing option.

   `firefox-profile-activate.swift:15` uses `activateIgnoringOtherApps`. Apple marks this option deprecated and warns that it can steal focus from the user. Use the current cooperative activation behavior and keep only the window-selection behavior needed by this tool. See [Apple's activation options](https://developer.apple.com/documentation/appkit/nsapplication/activationoptions) and [`NSRunningApplication.activate(options:)`](https://developer.apple.com/documentation/appkit/nsrunningapplication/activate%28options%3A%29).

4. Treat the Profile Groups database as a private, versioned implementation detail.

   Firefox's own [`ProfilesDatastoreService.sys.mjs`](https://searchfox.org/firefox-main/source/toolkit/profile/ProfilesDatastoreService.sys.mjs) uses a `Profile Groups/<storeID>.sqlite` path and currently defines a `Profiles` table containing `path` and `name`. It also explicitly says consumers may query existing tables but must not create or modify schemas, and that schema changes must remain backwards-compatible across Firefox versions. The current `-readonly` query is the right safety direction, but callers must tolerate a missing database, lock, corruption, schema change, and a database that has no usable rows.

5. Keep one source of truth for profile discovery.

   The extension (`src/choose-profile.tsx:31-113`) and shell launcher (`firefox-profile-launcher.zsh:20-195`) independently parse `profiles.ini` and the Profile Groups database. They can drift in fallback rules, section matching, and path resolution. Consolidate discovery behind one local read-only adapter or define one stable machine-readable command contract that both callers use.

### SHOULD

1. Use Raycast's async hook for loading, errors, and refresh.

   The current `useEffect`/`useState` flow (`src/choose-profile.tsx:166-175`) loads once and has no refresh action. Raycast's [Context7-indexed `usePromise` documentation](https://developers.raycast.com/utilities/react-hooks/usepromise) provides `data`, `error`, `isLoading`, and `revalidate`. For this command, use `usePromise`, not `useCachedPromise`, because the requirement is fresh profile discovery when the command opens. Add an explicit refresh action if profiles may be created or renamed while the command remains open.

2. Make the load failure state actionable.

   Raycast recommends `List.isLoading` for the initial state and a failure Toast for expected errors. The existing `List.EmptyView` (`src/choose-profile.tsx:215`) is useful, but should include a retry action and should not silently turn a database incompatibility into an apparently empty list. See Raycast's [List reference](https://developers.raycast.com/api-reference/user-interface/list), [usePromise reference](https://developers.raycast.com/utilities/react-hooks/usepromise), and [Toast reference](https://developers.raycast.com/api-reference/feedback/toast).

3. Pass paths to the launch action, not names.

   This also makes the extension and launcher contract explicit: the list displays a name, while the action carries the validated absolute path. The shell already accepts an absolute directory (`firefox-profile-launcher.zsh:248-257`). Keep the path quoted and continue using `execFile`/argument arrays. Node documents that `execFile` does not invoke a shell by default; preserve that property and never concatenate user input into a shell command.

4. Make the profile parser stricter and symmetric.

   Match `Profile` sections with a numeric suffix instead of broad `startsWith("Profile")`, preserve Firefox's `IsRelative` semantics, and iterate all valid sections rather than stopping at the first missing numeric entry. Add tests for duplicate display names, missing `Profile0`, missing paths, paths containing spaces or Unicode, a locked database, and a database schema that lacks `name` or `path`.

5. Keep the mutable extension outside Home Manager.

   The current module correctly manages the Script Command and launcher/helper links while leaving the Raycast extension directory writable for `ray develop`. Raycast's [CLI documentation](https://developers.raycast.com/information/developer-tools/cli) documents `npx ray develop` as the development-mode path with hot reload and automatic import. Do not replace this with a Nix-store symlink to the extension directory.

### NICE TO HAVE

- Replace ad-hoc tab-separated SQLite output with a machine-readable format, or document the allowed character set. Tab/newline characters in profile names or paths can corrupt the current row protocol.
- Mark the default profile from the parsed Firefox data and launch that resolved path. A generic `/usr/bin/open -a Firefox` (`src/choose-profile.tsx:127-137`) delegates default selection to LaunchServices and does not prove which profile was opened.
- Keep the Profile Manager only as a separate, explicitly named maintenance command if profile creation or deletion is ever needed. It should not be a default/empty-argument action.

## Recommended implementation order

1. Remove the Profile Manager item and change the empty Script Command behavior to the normal default/profile-list path.
2. Pass absolute paths from the extension and make the launcher launch new Firefox processes asynchronously.
3. Replace deprecated AppKit activation options.
4. Consolidate profile discovery and add the failure/refresh/edge-case tests.
5. Re-run `npm run lint`, `npm run build`, the focused Raycast Nix check, and `make test-build`.

## Current assessment

The implementation now keeps Profile Manager out of the quick-switch UI, passes validated absolute paths, detaches new Firefox processes, uses cooperative AppKit activation, and exposes one read-only profile-discovery contract through the launcher. The extension consumes that contract with Raycast's async hook and an actionable failure state. The writable-extension/Home Manager split remains intact. Tab-separated output and explicit default-profile resolution remain possible future refinements.
