# Rootless Darwin Configuration Guide

이 가이드는 root 권한 없이 nix-darwin 구성을 적용하는 방법을 설명합니다.

## 개요

기존 `nix run .#build-switch`는 시스템 레벨 설정 때문에 root 권한이 필요했습니다.
이 rootless 접근법은 모든 설정을 사용자 레벨로 이동시켜 sudo 없이 작동합니다.

## 주요 변경사항

### 시스템 레벨에서 사용자 레벨로 이동된 설정

1. **macOS Defaults**: `system.defaults` → Home Manager activation scripts
2. **App Installation**: `/Applications` → `~/Applications`  
3. **System Activation**: `system.activationScripts` → `home.activation`
4. **Shell Configuration**: `environment.shells` → user-level zsh setup

### 새로운 구성 파일들

- `hosts/darwin/default-rootless.nix` - 최소한의 시스템 설정
- `modules/darwin/home-manager-rootless.nix` - 사용자 레벨 Home Manager 구성  
- `scripts/build-switch-rootless.sh` - Root 권한 없는 빌드/스위치 스크립트

## 사용법

### 1. Rootless 구성으로 빌드 및 적용

```bash
# Root 권한 없이 빌드 및 적용
nix run .#build-switch-rootless

# Verbose 모드로 실행
nix run .#build-switch-rootless -- --verbose

# 빌드만 하고 적용하지 않음 (테스트 목적)
nix run .#build-switch-rootless -- --dry-run

# 원래 시스템 구성 사용 (sudo 필요할 수 있음)
nix run .#build-switch-rootless -- --use-system-config
```

### 2. 스크립트 직접 실행

```bash
# 스크립트 직접 실행
./scripts/build-switch-rootless.sh

# 도움말 보기
./scripts/build-switch-rootless.sh --help
```

### 3. 사용자 레벨 설정 적용

빌드 후 다음 명령어들이 PATH에 추가됩니다:

```bash
# macOS 기본 설정 적용
apply-macos-defaults

# 키보드 입력 설정
setup-keyboard-input

# 사용자 앱 설치
install-user-apps
```

## 작동 방식

### 임시 Flake 생성

Rootless 빌드는 다음 과정을 거칩니다:

1. 임시 디렉토리에 프로젝트 복사
2. `hosts/darwin/default.nix`를 `default-rootless.nix`로 교체  
3. `modules/darwin/home-manager.nix`를 `home-manager-rootless.nix`로 교체
4. 임시 구성으로 빌드 및 적용

### 사용자 레벨 설정들

**macOS Defaults**:

- `defaults write` 명령을 사용자 도메인에 적용
- 시스템 재시작 없이 적용 가능한 설정들만 포함

**App Installation**:

- Apps는 `~/Applications`에 설치
- 가능한 경우 `/Applications`에 심볼릭 링크 생성
- Launch Services 호환성 유지

**Activation Scripts**:

- Home Manager의 `home.activation`을 사용
- 사용자 권한으로만 실행되는 스크립트들

## 제한사항

### 사용자 레벨로 이동할 수 없는 설정들

1. **System Shells**: `/etc/shells` 수정 불가
   - 사용자는 여전히 zsh 사용 가능
   - 시스템 기본 shell 변경은 수동 필요

2. **Global System Paths**: 시스템 PATH 수정 불가
   - 사용자 PATH는 정상 작동

3. **System Services**: launchd system services 불가
   - 사용자 services는 정상 작동

### 수동 설정이 필요한 항목들

일부 설정은 여전히 시스템 관리자 권한이 필요합니다:

```bash
# Nix trusted users 설정 (선택사항)
sudo vi /etc/nix/nix.custom.conf
# 추가: trusted-users = root @admin yourusername

# zsh를 시스템 쉘로 등록 (선택사항)  
echo "$(which zsh)" | sudo tee -a /etc/shells
```

## 트러블슈팅

### 일반적인 문제들

**빌드 실패**:

```bash
# Verbose 모드로 자세한 정보 확인
nix run .#build-switch-rootless -- --verbose

# Dry run으로 빌드만 테스트
nix run .#build-switch-rootless -- --dry-run
```

**설정 적용 안됨**:

```bash
# 사용자 레벨 설정 수동 적용
apply-macos-defaults
setup-keyboard-input
install-user-apps

# 로그아웃/로그인 필요할 수 있음
```

**앱이 Launch Services에서 인식 안됨**:

```bash
# Launch Services 데이터베이스 재구성
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user
```

### 디버깅

**빌드 로그 확인**:

```bash
# 임시 빌드 디렉토리에서 직접 빌드 테스트
nix build --impure .#darwinConfigurations.$(nix eval --impure --raw --expr 'builtins.currentSystem').system

# Home Manager 구성 확인  
nix eval --impure .#darwinConfigurations.$(nix eval --impure --raw --expr 'builtins.currentSystem').config.home-manager.users
```

## 마이그레이션

### 기존 시스템 구성에서 Rootless로 변경

1. **현재 설정 백업**:

   ```bash
   cp hosts/darwin/default.nix hosts/darwin/default-system.nix.bak
   cp modules/darwin/home-manager.nix modules/darwin/home-manager-system.nix.bak
   ```

2. **Rootless 구성 테스트**:

   ```bash
   nix run .#build-switch-rootless -- --dry-run
   ```

3. **적용 및 검증**:

   ```bash
   nix run .#build-switch-rootless
   # 모든 앱과 설정이 정상 작동하는지 확인
   ```

### 다시 시스템 구성으로 돌아가기

```bash
# 원래 시스템 구성 사용
nix run .#build-switch-rootless -- --use-system-config

# 또는 기존 build-switch 사용 (sudo 필요)
nix run .#build-switch
```

## 장점 및 단점

### 장점

- ✅ Root 권한 불필요
- ✅ 빠른 빌드 및 적용  
- ✅ 사용자별 격리
- ✅ 안전한 테스트 환경

### 단점

- ❌ 일부 시스템 설정 제한
- ❌ Global services 불가
- ❌ 수동 설정 필요한 항목들 존재
- ❌ Launch Services 호환성 이슈 가능

## 결론

Rootless 구성은 개인 dotfiles 관리에 적합한 접근법입니다. 대부분의 개발 환경 설정을 root 권한 없이 관리할 수 있으며, CI/CD 환경이나 권한이 제한된 환경에서도 활용 가능합니다.

시스템 관리자 권한이 필요한 고급 설정이 필요한 경우에만 기존 `build-switch`를 사용하는 것을 권장합니다.
