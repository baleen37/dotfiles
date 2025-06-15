# Performance optimization settings for Nix builds
{ lib }:

{
  # Nix daemon settings for optimal performance
  nixSettings = {
    # Parallel building
    max-jobs = "auto";  # Use all available cores
    cores = 0;          # Use all cores for each job

    # Build optimization
    sandbox = true;
    sandbox-fallback = false;
    keep-outputs = true;
    keep-derivations = true;

    # Network optimization
    http-connections = 50;  # Increase parallel downloads
    connect-timeout = 5;    # Faster timeout for unresponsive servers
    download-attempts = 3;  # Retry failed downloads

    # Substituter configuration
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];

    # Garbage collection
    gc-keep-outputs = true;
    gc-keep-derivations = true;
    min-free = 1073741824;      # 1GB minimum free space
    max-free = 10737418240;     # 10GB to free when GC runs

    # Experimental features
    experimental-features = [
      "nix-command"
      "flakes"
      "repl-flake"
    ];

    # Build log settings
    build-poll-interval = 1;    # Check build progress every second
    log-lines = 100;            # Show last 100 lines on failure

    # Security
    allowed-users = [ "@wheel" "@admin" ];
    trusted-users = [ "root" "@wheel" "@admin" ];
  };

  # Darwin-specific performance settings
  darwinSettings = {
    # Use case-sensitive APFS volume for better performance
    nix.volume.enable = true;
    nix.volume.name = "nix-store";

    # Optimize for Apple Silicon
    nix.extraOptions = ''
      # Use rosetta for x86_64 builds on Apple Silicon
      extra-platforms = x86_64-darwin aarch64-darwin

      # Increase inode cache
      narinfo-cache-negative-ttl = 0
      narinfo-cache-positive-ttl = 3600
    '';
  };

  # Build cache configuration
  cacheConfig = {
    # Local cache settings
    localCache = {
      enable = true;
      path = "/var/cache/nix";
      maxSize = "50G";
      priority = 10;  # Prefer local cache
    };

    # Remote cache settings
    remoteCache = {
      enable = true;
      pushTo = null;  # Set to push builds to cachix
      priority = 20;
    };
  };

  # Optimization tips as comments
  tips = {
    beforeBuild = ''
      # Performance tips before building:
      # 1. Close unnecessary applications to free RAM
      # 2. Ensure at least 10GB free disk space
      # 3. Connect to fast, stable internet
      # 4. Run 'nix store gc' to clean old builds
      # 5. Use 'caffeinate' on macOS to prevent sleep
    '';

    duringBuild = ''
      # Monitor build progress:
      # - Use 'nix build -L' for detailed logs
      # - Watch system resources with 'htop'
      # - Check disk usage with 'df -h'
      # - Monitor network with 'nettop' (macOS) or 'iftop'
    '';

    afterBuild = ''
      # Post-build optimization:
      # 1. Run 'nix store optimise' to deduplicate
      # 2. Consider 'nix store gc --max 5G' to free space
      # 3. Update binary caches with successful builds
    '';
  };

  # Helper script for performance tuning
  tunePerformance = ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo "Optimizing Nix performance..."

    # Increase file descriptor limits
    ulimit -n 4096

    # Clear DNS cache (macOS)
    if [[ "$(uname)" == "Darwin" ]]; then
      sudo dscacheutil -flushcache
      sudo killall -HUP mDNSResponder
    fi

    # Optimize Nix store
    echo "Optimizing Nix store..."
    nix store optimise

    # Clean old generations
    echo "Cleaning old generations..."
    nix-collect-garbage -d --delete-older-than 7d

    # Warm up binary cache
    echo "Warming up binary cache..."
    nix path-info --all | head -100 | xargs nix path-info --store https://cache.nixos.org

    echo "Performance optimization complete!"
  '';
}
