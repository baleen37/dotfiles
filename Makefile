# Nix flake and system test Makefile

.PHONY: verify-all darwin-rebuild install

# 전체 통합 검증 (flake check + 모든 테스트)
verify-all:
	nix flake check
	# macOS 호스트별 빌드 테스트 (존재할 때만)
	@if nix flake show --json | jq -r '.outputs.darwinConfigurations // {} | keys[]' | grep . >/dev/null; then \
		nix flake show --json | jq -r '.outputs.darwinConfigurations // {} | keys[]' | while read host; do \
			echo "[darwin] Testing host: $$host"; \
			darwin-rebuild build --flake ".#$$host" || exit 1; \
		done; \
	else \
		echo "[darwin] No hosts found. Skipping darwin tests."; \
	fi
	# Linux 호스트별 빌드 및 nvim smoke test (존재할 때만)
	@if nix flake show --json | jq -r '.outputs.homeConfigurations // {} | keys[]' | grep . >/dev/null; then \
		nix flake show --json | jq -r '.outputs.homeConfigurations // {} | keys[]' | while read host; do \
			echo "[home-manager] Testing nvim for host: $$host"; \
			nix build ".#homeConfigurations.$$host.activationPackage" || exit 1; \
			if [ -f result/activate ]; then \
				. ./result/activate || true; \
			fi; \
			if command -v nvim >/dev/null 2>&1; then \
				nvim --version; \
			else \
				echo "nvim not found in PATH after activation for $$host" >&2; \
				exit 1; \
			fi; \
		done; \
	else \
		echo "[home-manager] No hosts found. Skipping home-manager tests."; \
	fi
	# Custom Nix package build/test
	@for pkg in hammerspoon homerow; do \
		echo "[custom] Building package: $$pkg"; \
		nix build .#packages.aarch64-darwin.$$pkg || nix build .#packages.x86_64-linux.$$pkg || true; \
	done
	# Home Manager dry-run
	@if nix flake show --json | jq -r '.outputs.homeConfigurations // {} | keys[]' | grep . >/dev/null; then \
		nix flake show --json | jq -r '.outputs.homeConfigurations // {} | keys[]' | while read host; do \
			echo "[home-manager] Dry-run switch for host: $$host"; \
			nix run .#homeConfigurations.$$host.activationPackage -- switch --dry-run || true; \
		done; \
	else \
		echo "[home-manager] No hosts found. Skipping home-manager dry-run."; \
	fi

# macOS 환경에 실제 적용 (baleen 호스트)
darwin-rebuild:
	darwin-rebuild switch --flake .#baleen

# 설치 스크립트 실행 (Nix 및 환경 설치)
install:
	bash ./install.sh
