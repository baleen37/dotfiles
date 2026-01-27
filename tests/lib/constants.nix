# Test Constants
#
# Centralized magic numbers used across tests.
# Each constant includes documentation explaining why it has its specific value.

{
  pkgs,
  lib,
}:

rec {
  # ===== Darwin Performance Constants =====

  # NSWindowResizeTime: Window resize animation duration (seconds)
  # Value: 0.1 (100ms)
  # Rationale: Fastest perceivable resize without feeling jarring.
  # Default macOS is ~0.2, faster values (<0.05) cause visual glitches.
  darwinWindowResizeTime = 0.1;

  # Dock autohide delay: Time before dock appears when hovering (seconds)
  # Value: 0.0 (instant)
  # Rationale: Instant feedback improves workflow speed.
  # Default is 0.1, which creates noticeable lag.
  darwinDockAutohideDelay = 0.0;

  # Dock autohide time modifier: Dock appearance animation speed (seconds)
  # Value: 0.15 (150ms)
  # Rationale: Fast enough to feel responsive, slow enough to be smooth.
  # Values <0.1 feel abrupt, >0.3 feel sluggish.
  darwinDockAutohideTimeModifier = 0.15;

  # Dock expose animation duration: Mission Control animation speed (seconds)
  # Value: 0.2 (200ms)
  # Rationale: Quick transitions between desktops.
  # Default is 0.25, faster values (<0.15) cause frame drops.
  darwinExposeAnimationDuration = 0.2;

  # Dock tile size: Icon size in pixels
  # Value: 48
  # Rationale: Balance between visibility and screen real estate.
  # Default is 64, smaller values (<40) reduce clickability.
  darwinDockTileSize = 48;

  # AppleFontSmoothing: Font rendering quality level
  # Value: 1
  # Rationale: Reduced font smoothing for sharper text and better performance.
  # 0 = disabled, 1 = reduced (medium), 2 = full (default), 3 = heavy
  darwinFontSmoothing = 1;

  # KeyRepeat: Keyboard repeat rate (delay between repeated characters in 1/60s)
  # Value: 1 (fastest possible, ~16ms between repeats)
  # Rationale: Maximum speed for rapid navigation and editing.
  # Range: 1-120 (lower is faster), GUI minimum is 2.
  darwinKeyRepeat = 1;

  # InitialKeyRepeat: Delay before key repeat starts (in 1/60s)
  # Value: 10 (~167ms initial delay)
  # Rationale: Fast response while preventing accidental repeats.
  # Range: 10-120 (lower is faster), GUI minimum is 15.
  darwinInitialKeyRepeat = 10;

  # Trackpad scaling: Cursor movement speed multiplier
  # Value: 3.0 (maximum speed)
  # Rationale: Fastest cursor movement for large screens.
  # Range: 0.0-3.0, -1 disables acceleration.
  darwinTrackpadScaling = 3.0;

  # Scroll wheel scaling: Scroll speed multiplier
  # Value: 1.0 (maximum speed)
  # Rationale: Fastest scrolling for long documents.
  # Range: 0.0-1.0, -1 disables acceleration.
  darwinScrollwheelScaling = 1.0;

  # Keyboard hotkey parameters
  # Used for cmd+shift+space and control+space input source switching
  # Values are derived from macOS HIToolbox/Events.h
  darwinHotkeySpaceKeyCode = 49; # kVK_Space
  darwinHotkeyCmdModifier = 1048576; # cmdKey (256 * 4096)
  darwinHotkeyShiftModifier = 131072; # shiftKey (256 * 512)
  darwinHotkeyCtrlModifier = 262144; # controlKey (256 * 1024)

  # ===== Starship Prompt Constants =====

  # command_timeout: Maximum time to wait for commands (milliseconds)
  # Value: 1000 (1 second)
  # Rationale: Balance between responsiveness and allowing slow commands.
  # Default is 500, which is too fast for some development tools.
  starshipCommandTimeout = 1000;

  # scan_timeout: Maximum time to scan for files (milliseconds)
  # Value: 30 (seconds)
  # Rationale: Prevents hanging on large directories.
  # Default is 30, lower values (<10) cause timeouts on big projects.
  starshipScanTimeout = 30;

  # cmd_duration min_time: Minimum command duration to display (milliseconds)
  # Value: 3000 (3 seconds)
  # Rationale: Only show duration for noticeably slow commands.
  # Values <2000 create visual noise for normal operations.
  starshipCmdDurationMinTime = 3000;

  # directory truncation_length: Number of path segments to show
  # Value: 3
  # Rationale: Show enough context for navigation while keeping prompt compact.
  # Values <2 lose too much context, >5 make prompt too long.
  starshipDirectoryTruncationLength = 3;

  # ===== Tmux Constants =====

  # historyLimit: Maximum number of lines in history per pane
  # Value: 50000
  # Rationale: Balance between searchable history and memory usage.
  # Default is 2000, which is too small for development work.
  tmuxHistoryLimit = 50000;

  # display-time: Duration of message display (milliseconds)
  # Value: 2000 (2 seconds)
  # Rationale: Long enough to read, short enough to not obstruct.
  # Default is 3000, which feels too long for frequent messages.
  tmuxDisplayTime = 2000;

  # repeat-time: Timeout for repeating commands (milliseconds)
  # Value: 500 (500ms)
  # Rationale: Allows rapid repeated commands without accidental triggers.
  # Default is 500, lower values (<200) cause accidental repeats.
  tmuxRepeatTime = 500;

  # ===== Vim Constants =====

  # history: Number of command history entries to keep
  # Value: 1000
  # Rationale: Sufficient history for development sessions.
  # Default is 50, which is too small for productive editing.
  vimHistory = 1000;

  # ===== Performance Test Constants =====

  # Fast operation timeout (milliseconds)
  # Value: 100
  # Rationale: Should complete almost instantly.
  perfFastTimeout = 100;

  # Medium operation timeout (milliseconds)
  # Value: 500
  # Rationale: Quick operations that may do some work.
  perfMediumTimeout = 500;

  # Slow operation timeout (milliseconds)
  # Value: 1000
  # Rationale: Operations that may process data.
  perfSlowTimeout = 1000;

  # Very slow operation timeout (milliseconds)
  # Value: 5000
  # Rationale: Heavy computations or complex operations.
  perfVerySlowTimeout = 5000;

  # Small memory allocation (bytes)
  # Value: 1 * 1024 * 1024 (1 MB)
  # Rationale: Minimal allocation for small data structures.
  perfSmallMemory = 1 * 1024 * 1024;

  # Medium memory allocation (bytes)
  # Value: 10 * 1024 * 1024 (10 MB)
  # Rationale: Moderate allocation for typical operations.
  perfMediumMemory = 10 * 1024 * 1024;

  # Large memory allocation (bytes)
  # Value: 50 * 1024 * 1024 (50 MB)
  # Rationale: Large allocation for stress testing.
  perfLargeMemory = 50 * 1024 * 1024;

  # ===== String Length Validation Constants =====

  # Maximum git command length
  # Value: 200
  # Rationale: Prevents absurdly long commands while allowing complex aliases.
  gitMaxCommandLength = 200;

  # Maximum git pattern length
  # Value: 200
  # Rationale: Prevents abuse while allowing complex patterns.
  gitMaxPatternLength = 200;

  # Maximum git name length
  # Value: 100
  # Rationale: RFC 5322 allows longer, but 100 is practical for display.
  gitMaxNameLength = 100;

  # Maximum git email length
  # Value: 254
  # Rationale: RFC 5321 maximum email length.
  gitMaxEmailLength = 254;

  # Maximum reasonable entry count for collections
  # Value: 100
  # Rationale: Balance between flexibility and performance.
  gitMaxEntryCount = 100;

  # ===== Zsh/Fzf Constants =====

  # Fzf preview line range
  # Value: 500
  # Rationale: Shows enough context without overwhelming the preview.
  fzfPreviewLineRange = 500;

  # Fzf tree preview head limit
  # Value: 200
  # Rationale: Shows directory structure without excessive output.
  fzfTreeHeadLimit = 200;

  # ===== Build Performance Constants =====

  # Zsh history size
  # Value: 10000
  # Rationale: Sufficient history for development work.
  zshHistorySize = 10000;

  # GPG agent default cache TTL (seconds)
  # Value: 1800 (30 minutes)
  # Rationale: Balance between security and convenience.
  gpgDefaultCacheTtl = 1800;

  # Performance regression thresholds (percentage of baseline)
  # Value: 0.3 (30%), 0.6 (60%), 0.9 (90%)
  # Rationale: Progressive limits for small, medium, large configs.
  perfRegressionThresholdSmall = 0.3;
  perfRegressionThresholdMedium = 0.6;
  perfRegressionThresholdLarge = 0.9;

  # Test data sizes for performance tests
  # Value: 1000, 5000, 10000
  # Rationale: Progressive sizes to test scaling.
  perfTestSmallSize = 1000;
  perfTestMediumSize = 5000;
  perfTestLargeSize = 10000;

  # ===== VM Test Constants =====

  # VM memory size (MB)
  # Value: 2048 (2 GB)
  # Rationale: Minimum for comfortable development work.
  vmMemorySize = 2048;

  # VM disk size (MB)
  # Value: 4096 (4 GB)
  # Rationale: Sufficient for testing without excessive space.
  vmDiskSize = 4096;

  # Shell history limit
  # Value: 5000
  # Rationale: Good balance for test sessions.
  shellHistoryLimit = 5000;

  # ===== Tmux Configuration Validation Constants =====

  # Minimum tmux config length for validation
  # Value: 500
  # Rationale: Ensures substantial configuration is present.
  tmuxMinConfigLength = 500;

  # Maximum tmux config length to read for validation
  # Value: 1000
  # Rationale: Prevents reading entire config for validation check.
  tmuxMaxConfigReadLength = 1000;

  # ===== Content Validation Constants =====

  # Minimum file content length for validation
  # Value: 100
  # Rationale: Ensures file has meaningful content.
  minContentLength = 100;

  # ===== Mac App Store Constants =====

  # Magnet app ID
  # Value: 441258766
  # Rationale: Window management tool with multi-monitor support.
  # Obtained via: mas search Magnet
  masAppMagnet = 441258766;

  # WireGuard app ID
  # Value: 1451685025
  # Rationale: Lightweight, secure VPN client.
  # Obtained via: mas search WireGuard
  masAppWireGuard = 1451685025;

  # KakaoTalk app ID
  # Value: 869223134
  # Rationale: Communication platform.
  # Obtained via: mas search KakaoTalk
  masAppKakaoTalk = 869223134;

  # ===== Memory Size Test Constants =====

  # Expected memory size for validation test
  # Value: 8192
  # Rationale: Specific test value for memory estimation.
  expectedMemorySize = 8192;

  # ===== Performance Test Result Constants =====

  # Expected result value for test
  # Value: 285
  # Rationale: Expected sum of squares from 0 to 9.
  expectedTestResult = 285;

  # Expected count value for test
  # Value: 10
  # Rationale: Number of iterations in test.
  expectedTestCount = 10;

  # ===== User Property Test Constants =====

  # Minimum full name length
  # Value: 2
  # Rationale: Minimum reasonable name length (e.g., "Al").
  minFullNameLength = 2;

  # Maximum full name length
  # Value: 100
  # Rationale: Practical limit for display purposes.
  maxFullNameLength = 100;

  # Minimum email length
  # Value: 5
  # Rationale: Minimum valid email (e.g., "a@b.c").
  minEmailLength = 5;

  # Maximum email length
  # Value: 254
  # Rationale: RFC 5321 maximum email length.
  maxEmailLength = 254;

  # ===== Trend Analysis Test Constants =====

  # Base duration for trend tests (milliseconds)
  # Value: 1000
  # Rationale: Baseline duration for stable performance.
  trendBaseDuration = 1000;

  # Base memory for trend tests (bytes)
  # Value: 50000000 (50 MB)
  # Rationale: Baseline memory for typical operations.
  trendBaseMemory = 50000000;

  # Duration increment for trend tests (milliseconds)
  # Value: 50
  # Rationale: Small increment to detect gradual degradation.
  trendDurationIncrement = 50;

  # Memory increment for trend tests (bytes)
  # Value: 1000000 (1 MB)
  # Rationale: Small increment to detect memory leaks.
  trendMemoryIncrement = 1000000;

  # Slow test baseline duration (milliseconds)
  # Value: 2500
  # Rationale: Baseline for intentionally slow operations.
  trendSlowBaselineDuration = 2500;

  # Slow test baseline memory (bytes)
  # Value: 80000000 (80 MB)
  # Rationale: Baseline for memory-intensive operations.
  trendSlowBaselineMemory = 80000000;

  # Improved test baseline duration (milliseconds)
  # Value: 950
  # Rationale: Shows performance improvement from optimization.
  trendImprovedBaselineDuration = 950;
}
