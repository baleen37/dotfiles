# Nix flake and system test Makefile

.PHONY: test darwin-rebuild

# Run Nix flake check

test:
	nix flake check

# Run darwin-rebuild switch (macOS only)
darwin-rebuild:
	darwin-rebuild switch --flake .#baleen
