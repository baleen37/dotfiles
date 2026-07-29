# tests/lib/constants.nix
#
# Values that appear in both a configuration module and the test asserting it.
# Keeping them here means a deliberate tuning change is a one-line edit, while an
# accidental one still fails a check.
#
# Only add a constant when a test actually references it — an unreferenced
# constant is documentation pretending to be code.

_:

{
  # ===== Darwin performance defaults (users/shared/darwin/default.nix) =====

  # NSWindowResizeTime, seconds. macOS defaults to ~0.2; below 0.05 the
  # animation glitches.
  darwinWindowResizeTime = 0.1;

  # Dock hover reveal delay, seconds. The 0.1 default reads as lag.
  darwinDockAutohideDelay = 0.0;

  # Dock reveal animation, seconds. Under 0.1 feels abrupt, over 0.3 sluggish.
  darwinDockAutohideTimeModifier = 0.15;

  # Mission Control transition, seconds. Under 0.15 drops frames.
  darwinExposeAnimationDuration = 0.2;

  # Dock icon size, pixels. Under 40 hurts clickability.
  darwinDockTileSize = 48;

  # AppleFontSmoothing: 0 off, 1 reduced, 2 full (default), 3 heavy.
  darwinFontSmoothing = 1;

  # ===== Starship (users/shared/programs/starship.nix) =====

  # command_timeout, ms. The 500 default is too tight for some dev tools.
  starshipCommandTimeout = 1000;

  # scan_timeout, ms. Keeps the prompt from hanging in large trees.
  starshipScanTimeout = 30;

  # cmd_duration.min_time, ms. Below 2000 this is visual noise.
  starshipCmdDurationMinTime = 3000;

  # directory.truncation_length, path segments.
  starshipDirectoryTruncationLength = 3;
}
