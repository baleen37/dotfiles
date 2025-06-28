self: super: with super; {
  google-gemini-cli = 
    let
      geminiScript = writeShellScriptBin "gemini" ''
    #!/usr/bin/env bash
    
    # 캐시 디렉토리 설정
    CACHE_DIR="$HOME/.cache/google-gemini-cli"
    NODE_MODULES="$CACHE_DIR/node_modules"
    GEMINI_CLI="$NODE_MODULES/@google/gemini-cli/dist/index.js"
    
    # 캐시 디렉토리 생성
    mkdir -p "$CACHE_DIR"
    
    # 패키지가 설치되어 있지 않거나 24시간이 지났으면 재설치
    if [[ ! -f "$GEMINI_CLI" ]] || [[ $(find "$GEMINI_CLI" -mtime +1 2>/dev/null) ]]; then
      echo "Installing/updating @google/gemini-cli..." >&2
      cd "$CACHE_DIR"
      
      # npm이 없으면 에러
      if ! command -v npm &> /dev/null; then
        echo "Error: npm is required but not found in PATH" >&2
        echo "Install Node.js: nix-shell -p nodejs npm" >&2
        exit 1
      fi
      
      # 최신 버전 설치
      npm install @google/gemini-cli@latest --no-save --no-package-lock 2>/dev/null || {
        echo "Error: Failed to install @google/gemini-cli" >&2
        exit 1
      }
    fi
    
    # CLI 실행
    if [[ -f "$GEMINI_CLI" ]]; then
      exec ${nodejs_22}/bin/node "$GEMINI_CLI" "$@"
    else
      echo "Error: @google/gemini-cli not found" >&2
      exit 1
    fi
  '';
    in
    symlinkJoin {
      name = "google-gemini-cli";
      paths = [ geminiScript ];
      postBuild = ''
        # gemini 명령어를 google-gemini-cli로도 사용할 수 있도록 심볼릭 링크 생성
        ln -sf $out/bin/gemini $out/bin/google-gemini-cli
      '';
    };
}