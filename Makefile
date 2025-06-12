.DEFAULT_GOAL := help

ARCH := $(shell uname -m)
OS := $(shell uname -s | tr A-Z a-z)
NIX := nix --extra-experimental-features 'nix-command flakes'

# Helper function to run command in Nix dev shell if tool not available
define run_in_nix_if_needed
	@if command -v $(1) >/dev/null 2>&1; then \
		$(2); \
	else \
		echo "⚠️  $(1) not found. Running via nix develop..."; \
		$(NIX) develop --command bash -c "$(2)"; \
	fi
endef

help:
	@echo "Available targets:"
	@echo "  lint        - Run pre-commit lint"
	@echo "  smoke       - Run nix flake checks for all systems"
	@echo "  test        - Run all tests (unit, integration, e2e)"
	@echo "  test-unit   - Run unit tests only"
	@echo "  test-integration - Run integration tests only"
	@echo "  test-e2e    - Run end-to-end tests only"
	@echo "  test-perf   - Run performance tests only"
	@echo "  test-contract - Run contract tests only"
	@echo "  test-security - Run security tests only"
	@echo "  test-compatibility - Run compatibility tests only"
	@echo "  test-fast   - Run fast tests (unit + integration)"
	@echo "  test-slow   - Run slow tests (e2e + performance)"
	@echo "  test-status - Show test framework status"
	@echo "  build       - Build all Darwin and NixOS configurations"
	@echo "  switch      - Apply configuration on the current machine (HOST=<system> optional)"

lint:
	$(call run_in_nix_if_needed,pre-commit,pre-commit run --all-files)

ifdef SYSTEM
smoke:
	$(NIX) flake check --impure --system $(SYSTEM) --no-build $(ARGS)
else
smoke:
	$(NIX) flake check --impure --all-systems --no-build $(ARGS)
endif

test:
	$(NIX) flake check --impure --no-build

test-unit:
	@echo "Running unit tests..."
	@SYSTEM=$$(nix eval --impure --expr 'builtins.currentSystem' | tr -d '"'); \
	$(NIX) build --impure --no-link ".#checks.$$SYSTEM.basic_functionality_unit" $(ARGS) && echo "✓ Unit tests passed"

test-integration:
	@echo "Running integration tests..."
	@SYSTEM=$$(nix eval --impure --expr 'builtins.currentSystem' | tr -d '"'); \
	$(NIX) build --impure --no-link ".#checks.$$SYSTEM.package_availability_integration" $(ARGS) && echo "✓ Integration tests passed"

test-e2e:
	@echo "Running end-to-end tests..."
	@SYSTEM=$$(nix eval --impure --expr 'builtins.currentSystem' | tr -d '"'); \
	$(NIX) build --impure --no-link ".#checks.$$SYSTEM.system_build_e2e" $(ARGS) && echo "✓ E2E tests passed"

test-perf:
	@echo "Running performance tests..."
	@SYSTEM=$$(nix eval --impure --expr 'builtins.currentSystem' | tr -d '"'); \
	$(NIX) build --impure --no-link ".#checks.$$SYSTEM.build_time_perf" $(ARGS) && echo "✓ Performance tests completed"

test-contract:
	@echo "Running contract tests..."
	@SYSTEM=$$(nix eval --impure --expr 'builtins.currentSystem' | tr -d '"'); \
	$(NIX) build --impure --no-link ".#checks.$$SYSTEM.flake_outputs_contract" $(ARGS) && \
	$(NIX) build --impure --no-link ".#checks.$$SYSTEM.module_interface_contract" $(ARGS) && \
	echo "✓ Contract tests passed"

test-security:
	@echo "Running security tests..."
	@SYSTEM=$$(nix eval --impure --expr 'builtins.currentSystem' | tr -d '"'); \
	$(NIX) build --impure --no-link ".#checks.$$SYSTEM.secrets_exposure_security" $(ARGS) && \
	$(NIX) build --impure --no-link ".#checks.$$SYSTEM.permissions_security" $(ARGS) && \
	echo "✓ Security tests passed"

test-compatibility:
	@echo "Running compatibility tests..."
	@SYSTEM=$$(nix eval --impure --expr 'builtins.currentSystem' | tr -d '"'); \
	$(NIX) build --impure --no-link ".#checks.$$SYSTEM.version_compatibility" $(ARGS) && \
	$(NIX) build --impure --no-link ".#checks.$$SYSTEM.migration_compatibility" $(ARGS) && \
	echo "✓ Compatibility tests passed"

test-fast:
	@echo "Running fast tests (unit + integration)..."
	@$(MAKE) test-unit
	@$(MAKE) test-integration
	@echo "✓ Fast test suite completed"

test-slow:
	@echo "Running slow tests (e2e + performance)..."
	@$(MAKE) test-e2e
	@$(MAKE) test-perf
	@echo "✓ Slow test suite completed"

test-status:
	@echo "Checking test framework status..."
	@SYSTEM=$$(nix eval --impure --expr 'builtins.currentSystem' | tr -d '"'); \
	$(NIX) build --impure --no-link ".#checks.$$SYSTEM.framework_status" $(ARGS)

build-linux:
	$(NIX) build --impure --no-link ".#nixosConfigurations.x86_64-linux.config.system.build.toplevel" $(ARGS)
	$(NIX) build --impure --no-link ".#nixosConfigurations.aarch64-linux.config.system.build.toplevel" $(ARGS)

build-darwin:
	$(NIX) build --impure --no-link ".#darwinConfigurations.x86_64-darwin.system" $(ARGS)
	$(NIX) build --impure --no-link ".#darwinConfigurations.aarch64-darwin.system" $(ARGS)

build: build-linux build-darwin

switch:
	@OS=$$(uname -s); \
	ARCH=$$(uname -m); \
	if [ "$${OS}" = "Darwin" ]; then \
	DEFAULT_SYSTEM="$${ARCH}-darwin"; \
	else \
	DEFAULT_SYSTEM="$${ARCH}-linux"; \
	fi; \
	TARGET=${HOST-$${DEFAULT_SYSTEM}}; \
	if [ "$${OS}" = "Darwin" ]; then \
	nix --extra-experimental-features 'nix-command flakes' build --impure .#darwinConfigurations.$${TARGET}.system $(ARGS); \
	sudo ./result/sw/bin/darwin-rebuild switch --flake .#$${TARGET} $(ARGS); \
	unlink ./result; \
	else \
	sudo SSH_AUTH_SOCK=$$SSH_AUTH_SOCK /run/current-system/sw/bin/nixos-rebuild switch --impure --flake .#$${TARGET} $(ARGS); \
	fi

.PHONY: help lint smoke test test-unit test-integration test-e2e test-perf test-contract test-security test-compatibility test-fast test-slow test-status build build-linux build-darwin switch
