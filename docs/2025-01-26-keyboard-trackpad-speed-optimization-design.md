# 키보드 및 트랙패드 속도 최적화 설계

**날짜**: 2025-01-26
**상태**: Approved
**목표**: darwin.nix에 최대 속도의 키보드 및 트랙패드 설정 추가

## 개요

파워유저/개발자를 위한 최고속 입력 환경을 제공하기 위해 darwin.nix에 키보드 반복 속도와 트랙패드 속도 설정을 추가합니다.

### 설정 범위

1. **키보드 속도**: macOS GUI 제한을 초과하는 최고속 설정
   - KeyRepeat: 1 (macOS GUI 최소값 2보다 빠름)
   - InitialKeyRepeat: 10 (macOS GUI 최소값 15보다 빠름)

2. **트랙패드 속도**: 모든 관련 속도를 최대로 설정
   - Tracking Speed: 3.0 (최대값)
   - Scrolling Speed: 1.0 (최대값)

3. **적용 위치**:
   - `system.defaults.NSGlobalDomain`: 모든 속도 설정 추가
   - `system.activationScripts.configureKeyboard`: 중복된 KeyRepeat 설정 제거

## 설계 상세

### 1. NSGlobalDomain 키보드 및 트랙패드 설정

**파일**: `users/shared/darwin.nix`
**위치**: 75-99 라인 영역 (NSGlobalDomain 섹션)

**추가할 설정**:

```nix
NSGlobalDomain = {
  # ... 기존 UI Performance 설정들 ...

  # Input Optimization
  NSAutomaticCapitalizationEnabled = false;
  NSAutomaticSpellingCorrectionEnabled = false;
  NSAutomaticQuoteSubstitutionEnabled = false;
  NSAutomaticDashSubstitutionEnabled = false;
  NSAutomaticPeriodSubstitutionEnabled = false;
  ApplePressAndHoldEnabled = false; # Faster key repeat

  # Keyboard Speed (macOS GUI 제한을 초과하는 최고속 설정)
  KeyRepeat = 1; # 키 반복 속도 (1-120, 낮을수록 빠름, GUI 최소값: 2)
  InitialKeyRepeat = 10; # 초기 반복 지연 (10-120, 낮을수록 빠름, GUI 최소값: 15)

  # Trackpad Speed (최대 속도 설정)
  "com.apple.trackpad.scaling" = 3.0; # 커서 이동 속도 (0.0-3.0, 최대값)
  "com.apple.scrollwheel.scaling" = 1.0; # 스크롤 속도 (최대값, -1은 가속 비활성화)

  # ... 나머지 설정들 ...
};
```

**설명**:
- `KeyRepeat = 1`: 키를 누르고 있을 때 문자 반복 간격을 최소화 (약 15ms)
- `InitialKeyRepeat = 10`: 키를 누른 후 반복 시작까지의 지연을 최소화 (약 150ms)
- `com.apple.trackpad.scaling = 3.0`: 트랙패드 커서 이동 속도를 최대로 설정
- `com.apple.scrollwheel.scaling = 1.0`: 스크롤 속도를 최대로 설정 (-1로 변경하면 가속 비활성화)

**기술적 근거**:
- nix-darwin에서 `system.defaults.NSGlobalDomain`을 통해 모든 설정을 선언적으로 관리
- `com.apple.trackpad.scaling`과 `com.apple.scrollwheel.scaling`은 NSGlobalDomain에서 직접 지원됨 ([출처](https://mynixos.com/nix-darwin/option/system.defaults.NSGlobalDomain.%22com.apple.trackpad.scaling%22))
- activationScripts 대신 선언적 설정을 사용하여 재현성 향상

### 2. activationScripts.configureKeyboard 중복 제거

**파일**: `users/shared/darwin.nix`
**위치**: 179-221 라인 (configureKeyboard 섹션)

**삭제할 코드** (186-188 라인):

```nix
# 삭제: 중복된 키보드 속도 설정
# /usr/bin/defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
# /usr/bin/defaults write NSGlobalDomain KeyRepeat -int 2
# /usr/bin/defaults write NSGlobalDomain InitialKeyRepeat -int 25
```

**변경 후**:

```nix
system.activationScripts.configureKeyboard = {
  text = ''
    echo "⌨️  Configuring keyboard input sources..." >&2

    sleep 2

    # Note: KeyRepeat and InitialKeyRepeat are now managed in system.defaults.NSGlobalDomain

    # cmd+shift+space for input source switching (hotkey 60)
    /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 '{
        enabled = 1;
        value = {
            type = standard;
            parameters = (49, 1048576, 131072);  # space(49), cmd, shift
        };
    }'

    # ... 나머지 입력 소스 설정들 유지 ...
  '';
};
```

**이유**:
- `system.defaults.NSGlobalDomain`에서 이미 선언적으로 관리하므로 중복 제거
- 입력 소스 전환 관련 코드는 nix-darwin에서 아직 선언적 방법이 없으므로 유지
- 더 깔끔하고 일관된 구조

## 예상 효과

### 키보드

| 항목 | 기존 (activationScripts) | 변경 후 | 개선율 |
|------|-------------------------|---------|--------|
| 초기 반복 지연 | 25 (약 375ms) | 10 (약 150ms) | 2.5배 빠름 |
| 키 반복 간격 | 2 (약 30ms) | 1 (약 15ms) | 2배 빠름 |

**효과**:
- vim/emacs 같은 텍스트 에디터에서 hjkl 이동이 훨씬 빠름
- 터미널 작업 시 빠른 입력 가능
- 한글 타이핑 시에도 더 반응성 좋은 경험

### 트랙패드

| 항목 | 기존 | 변경 후 |
|------|------|---------|
| 커서 이동 속도 | 기본값 (약 1.0) | 3.0 (최대) |
| 스크롤 속도 | 기본값 | 1.0 (최대) |

**효과**:
- 개발 중 빠른 화면 이동 가능
- 긴 코드 파일 스크롤 시 효율적
- 멀티 모니터 환경에서 커서 이동 개선

## 적용 방법

```bash
# 1. 설정 적용
export USER=$(whoami)
make switch

# 2. 즉시 적용됨 (재시작 불필요)
```

## 값 조정 가이드

너무 빠르다고 느껴질 경우 다음과 같이 조정 가능:

**키보드**:
```nix
KeyRepeat = 2;           # 1→2 (약간 느리게)
InitialKeyRepeat = 15;   # 10→15 (초기 지연 증가)
```

**트랙패드**:
```nix
"com.apple.trackpad.scaling" = 2.5;      # 3.0→2.5
"com.apple.scrollwheel.scaling" = 0.75;  # 1.0→0.75
```

**스크롤 가속 비활성화**:
```nix
"com.apple.scrollwheel.scaling" = -1;  # 가속 완전 제거
```

## 주의사항

1. **시스템 재시작 불필요**: 설정은 즉시 적용됩니다
2. **사용자별 선호도**: 처음에는 속도가 너무 빠르게 느껴질 수 있으므로 점진적 조정 권장
3. **입력 소스 전환**: activationScripts의 한글/영문 전환 설정은 그대로 유지됩니다
4. **테스트**: 적용 후 텍스트 에디터와 브라우저에서 동작 확인 필요

## 기술 참고 자료

- [nix-darwin NSGlobalDomain trackpad scaling](https://mynixos.com/nix-darwin/option/system.defaults.NSGlobalDomain.%22com.apple.trackpad.scaling%22)
- [trackpad.nix example configuration](https://git.ctu.cx/nixfiles/tree/configurations/darwin/trackpad.nix.html)
- [macOS scrollwheel scaling settings](https://apple.stackexchange.com/questions/23189/change-the-mouse-wheel-scrolling-acceleration/45319)
- [nix-darwin KeyRepeat documentation](https://nix-darwin.github.io/nix-darwin/manual/index)

## 구현 체크리스트

- [ ] NSGlobalDomain에 KeyRepeat, InitialKeyRepeat 추가
- [ ] NSGlobalDomain에 trackpad.scaling, scrollwheel.scaling 추가
- [ ] activationScripts.configureKeyboard에서 중복 코드 제거
- [ ] `make test`로 설정 검증
- [ ] `make switch`로 적용
- [ ] 실제 동작 테스트 (vim, 브라우저 스크롤 등)
- [ ] 필요시 값 미세 조정
