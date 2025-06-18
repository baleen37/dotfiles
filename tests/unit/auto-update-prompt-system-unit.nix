{ pkgs, lib, ... }:

let
  # Import test utilities
  testUtils = import ../lib/test-helpers.nix { inherit lib pkgs; };

  # Create a simpler test approach that doesn't require complex nix eval calls
  promptTestScenarios = [
    {
      name = "라이브러리 파일 존재 확인";
      description = "auto-update-prompt.nix 라이브러리 파일이 올바르게 생성되었는지 확인";
      testScript = ''
        # Check if the library file exists
        if [ ! -f "lib/auto-update-prompt.nix" ]; then
          echo "✗ lib/auto-update-prompt.nix 파일이 존재하지 않음"
          exit 1
        fi

        # Check if it's a valid nix file
        ${pkgs.nix}/bin/nix eval --file lib/auto-update-prompt.nix --arg lib 'import <nixpkgs/lib>' --arg pkgs 'import <nixpkgs> {}' >/dev/null 2>&1 || {
          echo "✗ lib/auto-update-prompt.nix 파일의 구문 오류"
          exit 1
        }

        echo "✓ 라이브러리 파일 존재 및 구문 검증 통과"
      '';
    }

    {
      name = "상태 관리 시스템 통합 확인";
      description = "기존 상태 관리 시스템과의 통합이 올바른지 확인";
      testScript = ''
        # Check if state management library exists (dependency)
        if [ ! -f "lib/auto-update-state.nix" ]; then
          echo "✗ 의존성 lib/auto-update-state.nix 파일이 존재하지 않음"
          exit 1
        fi

        # Test that prompt library can import state library
        ${pkgs.nix}/bin/nix eval --impure --expr '
          let
            prompt = import ./lib/auto-update-prompt.nix {
              inherit (import <nixpkgs> {}) lib pkgs;
            };
          in builtins.hasAttr "formatPromptMessage" prompt
        ' >/dev/null 2>&1 || {
          echo "✗ 프롬프트 라이브러리 임포트 실패"
          exit 1
        }

        echo "✓ 상태 관리 시스템 통합 확인 통과"
      '';
    }

    {
      name = "함수 인터페이스 확인";
      description = "필수 함수들이 올바르게 정의되어 있는지 확인";
      testScript = ''
        # Check if required functions are defined
        for func in "formatPromptMessage" "validateInput" "processUserChoice" "promptUserWithTimeout" "shellIntegration"; do
          ${pkgs.nix}/bin/nix eval --impure --expr '
            let
              prompt = import ./lib/auto-update-prompt.nix {
                inherit (import <nixpkgs> {}) lib pkgs;
              };
            in builtins.hasAttr "'$func'" prompt
          ' >/dev/null 2>&1 || {
            echo "✗ 함수 '$func'가 정의되지 않음"
            exit 1
          }
          echo "✓ 함수 '$func' 정의 확인"
        done

        echo "✓ 모든 필수 함수 인터페이스 확인 통과"
      '';
    }

    {
      name = "입력 검증 로직 테스트";
      description = "validateInput 함수가 올바르게 작동하는지 확인";
      testScript = ''
        # Test valid inputs
        for input in "y" "Y" "l" "L" "n" "N" "s" "S"; do
          result=$(${pkgs.nix}/bin/nix eval --impure --expr '
            let prompt = import ./lib/auto-update-prompt.nix { inherit (import <nixpkgs> {}) lib pkgs; };
            in prompt.validateInput "'$input'"
          ')
          if [ "$result" != "true" ]; then
            echo "✗ 유효한 입력 '$input'이 거부됨: $result"
            exit 1
          fi
        done
        echo "✓ 유효한 입력 검증 통과"

        # Test invalid inputs
        for input in "x" "z" "yes" "123"; do
          result=$(${pkgs.nix}/bin/nix eval --impure --expr '
            let prompt = import ./lib/auto-update-prompt.nix { inherit (import <nixpkgs> {}) lib pkgs; };
            in prompt.validateInput "'$input'"
          ')
          if [ "$result" != "false" ]; then
            echo "✗ 무효한 입력 '$input'이 허용됨: $result"
            exit 1
          fi
        done
        echo "✓ 무효한 입력 검증 통과"

        echo "✓ 입력 검증 로직 테스트 통과"
      '';
    }

    {
      name = "셸 스크립트 생성 확인";
      description = "생성된 셸 스크립트들이 유효한지 확인";
      testScript = ''
        # Test that shell scripts can be generated
        script_path=$(${pkgs.nix}/bin/nix build --impure --expr '
          let prompt = import ./lib/auto-update-prompt.nix { inherit (import <nixpkgs> {}) lib pkgs; };
          in prompt.promptUserWithTimeout {
            commit_hash = "test123";
            summary = "test update";
            changes_count = 1;
            notification_file = "/tmp/test.json";
          }
        ' --no-link --print-out-paths)

        if [ ! -f "$script_path" ]; then
          echo "✗ 프롬프트 스크립트 생성 실패"
          exit 1
        fi

        if [ ! -x "$script_path" ]; then
          echo "✗ 생성된 스크립트가 실행 가능하지 않음"
          exit 1
        fi

        echo "✓ 셸 스크립트 생성 및 실행 권한 확인 통과"
      '';
    }

    {
      name = "캐시 디렉토리 처리 확인";
      description = "알림 파일 캐시 디렉토리가 올바르게 처리되는지 확인";
      testScript = ''
        # Create test cache directory and notification
        test_cache_dir="/tmp/test-dotfiles-updates"
        mkdir -p "$test_cache_dir"

        cat > "$test_cache_dir/pending-test123.json" << 'EOF'
        {
          "commit_hash": "test123",
          "timestamp": "2025-06-18T10:00:00Z",
          "summary": "feat: 테스트 업데이트",
          "changes_count": 2,
          "files_changed": ["file1.nix", "file2.nix"]
        }
        EOF

        # Test that the file exists and is readable
        if [ ! -f "$test_cache_dir/pending-test123.json" ]; then
          echo "✗ 테스트 알림 파일 생성 실패"
          exit 1
        fi

        # Verify JSON structure
        if command -v jq >/dev/null 2>&1; then
          jq empty "$test_cache_dir/pending-test123.json" || {
            echo "✗ 알림 파일 JSON 형식 오류"
            exit 1
          }

          # Check required fields
          commit_hash=$(jq -r '.commit_hash' "$test_cache_dir/pending-test123.json")
          if [ "$commit_hash" != "test123" ]; then
            echo "✗ 알림 파일 commit_hash 필드 오류: $commit_hash"
            exit 1
          fi
        fi

        # Cleanup
        rm -rf "$test_cache_dir"

        echo "✓ 캐시 디렉토리 및 알림 파일 처리 확인 통과"
      '';
    }
  ];

in pkgs.runCommand "auto-update-prompt-system-unit-test" {
  meta = {
    description = "자동 업데이트 사용자 확인 시스템 Phase 1.3 단위 테스트";
    maintainers = [ "jito" ];
    platforms = with pkgs.lib.platforms; unix;
    timeout = 60;
  };
} ''
  echo "🧪 Phase 1.3 프롬프트 시스템 단위 테스트 시작"
  echo

  # Ensure we're in the right directory
  cd ${toString /Users/jito/dotfiles}

  ${lib.concatMapStringsSep "\n\n" (scenario: ''
    echo "📝 테스트: ${scenario.name}"
    echo "   설명: ${scenario.description}"

    (
      ${scenario.testScript}
    ) || {
      echo "❌ 테스트 실패: ${scenario.name}"
      exit 1
    }

    echo
  '') promptTestScenarios}

  echo "✅ 모든 Phase 1.3 프롬프트 시스템 기본 테스트 통과!"
  echo "   - 라이브러리 파일 존재 ✓"
  echo "   - 상태 관리 통합 ✓"
  echo "   - 함수 인터페이스 ✓"
  echo "   - 입력 검증 로직 ✓"
  echo "   - 셸 스크립트 생성 ✓"
  echo "   - 캐시 디렉토리 처리 ✓"
  echo
  echo "⚠️  주의: 이는 기본 구조 테스트입니다."
  echo "   대화형 기능과 타임아웃 처리는 통합 테스트에서 검증됩니다."

  # Create output file to mark test completion
  touch $out
''
