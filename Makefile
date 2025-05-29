# Nix flake and system test Makefile

.PHONY: test maketest darwin-rebuild install

# Flake 구문/타입 검증 (빠른 테스트)
test:
	nix flake check
	# macOS 호스트별 빌드 테스트 (존재할 때만)
	@if nix eval --json '.#darwinConfigurations' 2>/dev/null | jq -r 'keys[]' | grep . >/dev/null; then \
		nix eval --json '.#darwinConfigurations' | jq -r 'keys[]' | while read host; do \
			echo "[darwin] Testing host: $$host"; \
			darwin-rebuild build --flake ".#$$host" || exit 1; \
		done; \
	else \
		echo "[darwin] No hosts found. At least one darwin host is required."; \
		exit 2; \
	fi
	# Linux 호스트별 빌드 및 nvim smoke test (존재할 때만)
	@if nix eval --json '.#homeConfigurations' 2>/dev/null | jq -r 'keys[]' | grep . >/dev/null; then \
		nix eval --json '.#homeConfigurations' | jq -r 'keys[]' | while read host; do \
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
		echo "[home-manager] No hosts found. At least one home-manager host is required."; \
		exit 2; \
	fi

# CI와 동일한 통합 테스트 (호스트별 빌드, nvim smoke test)
maketest:
	$(MAKE) test

# macOS 환경에 실제 적용 (baleen 호스트)
darwin-rebuild:
	darwin-rebuild switch --flake .#baleen

# 설치 스크립트 실행 (Nix 및 환경 설치)
install:
	bash ./install.sh
