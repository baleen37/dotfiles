# IntelliJ IDEA 플러그인 호환성 문제 해결 가이드

## 개요

이 가이드는 IntelliJ IDEA에서 발생하는 플러그인 호환성 문제를 진단하고 해결하는 방법을 제공합니다.

## 문제 증상

IntelliJ IDEA 실행 시 다음과 같은 경고 메시지가 나타날 수 있습니다:

```
WARN: Problems found loading plugins:
  The Python (id=Pythonid, path=~/Library/Application Support/JetBrains/IntelliJIdea2024.2/plugins/python, version=242.26775.15) plugin Plugin 'Python' (version '242.26775.15') is not compatible with the current version of the IDE, because it requires build 242.26775 or newer but the current build is IU-242.24807.4
```

## 자동 해결 도구

### 스크립트 사용법

dotfiles 저장소에 포함된 자동화 스크립트를 사용하여 문제를 해결할 수 있습니다:

```bash
# 플러그인 호환성 확인
./scripts/intellij-plugin-health-check

# 호환되지 않는 플러그인 자동 비활성화
./scripts/intellij-plugin-health-check fix

# IntelliJ IDEA 업데이트
./scripts/intellij-plugin-health-check update

# 전체 해결 (업데이트 + 플러그인 정리)
./scripts/intellij-plugin-health-check fix true
```

### 스크립트 기능

- **호환성 확인**: 설치된 플러그인과 IDE 버전 간의 호환성 검사
- **자동 업데이트**: Homebrew를 통한 IntelliJ IDEA 최신 버전 설치
- **플러그인 관리**: 호환되지 않는 플러그인 자동 비활성화
- **상세 로깅**: 문제 진단을 위한 자세한 정보 제공

## 수동 해결 방법

### 방법 1: IDE 업데이트 (권장)

1. **Homebrew 사용**:
   ```bash
   brew update
   brew upgrade --cask intellij-idea
   ```

2. **IDE 내에서 업데이트**:
   - `Help` → `Check for Updates...`
   - 업데이트가 있다면 안내에 따라 설치

3. **JetBrains Toolbox 사용**:
   - JetBrains Toolbox 애플리케이션 열기
   - IntelliJ IDEA 옆의 업데이트 버튼 클릭

### 방법 2: 플러그인 다운그레이드

1. `Settings` (⌘ + ,) → `Plugins` 이동
2. 문제가 되는 플러그인 찾기
3. 플러그인 비활성화:
   - 플러그인 옆의 체크박스 해제
   - `Apply` 클릭
4. IDE 재시작

### 방법 3: 플러그인 버전 관리

1. `Settings` → `Plugins` → `Installed`
2. 문제 플러그인 선택 → 톱니바퀴 아이콘 클릭
3. `Downgrade` 또는 `Uninstall` 선택
4. 호환되는 버전으로 재설치

## 예방 조치

### 정기적인 유지보수

다음 명령어를 주기적으로 실행하여 문제를 예방하세요:

```bash
# 주간 점검 (cron job으로 설정 가능)
./scripts/intellij-plugin-health-check

# 월간 전체 정리
./scripts/intellij-plugin-health-check fix true
```

### Nix 기반 자동화

dotfiles의 nix 설정을 통해 다음이 자동으로 관리됩니다:

- **IntelliJ IDEA 설치**: `modules/darwin/casks.nix`에서 Homebrew cask로 관리
- **버전 일관성**: 팀 전체가 동일한 개발 환경 사용
- **자동 업데이트**: 시스템 빌드 시 최신 버전 확인

### 플러그인 선택 가이드

필수 플러그인만 설치하여 호환성 문제를 최소화하세요:

#### 권장 플러그인
- **Language Support**: 사용하는 언어에 필요한 플러그인만
- **Git Integration**: 기본 제공되므로 추가 플러그인 불필요
- **Database Tools**: JetBrains 공식 플러그인 사용

#### 주의할 플러그인
- **Beta/Preview 플러그인**: 안정성 문제 가능성
- **커뮤니티 플러그인**: 업데이트 지연 가능성
- **중복 기능 플러그인**: 내장 기능과 겹치는 플러그인

## 문제 해결 체크리스트

플러그인 호환성 문제 발생 시 다음 순서로 확인하세요:

- [ ] IntelliJ IDEA 최신 버전 설치 여부
- [ ] 플러그인 버전 호환성 확인
- [ ] 불필요한 플러그인 제거
- [ ] IDE 설정 백업 및 초기화 (필요시)
- [ ] 플러그인 재설치
- [ ] IDE 재시작

## 추가 리소스

- [JetBrains Plugin Repository](https://plugins.jetbrains.com/)
- [IntelliJ IDEA 공식 문서](https://www.jetbrains.com/help/idea/)
- [Homebrew Cask 관리](https://github.com/Homebrew/homebrew-cask)

## 팀 협업 가이드

### 개발 환경 동기화

팀원들이 동일한 개발 환경을 유지하기 위해:

1. **dotfiles 최신 버전 사용**:
   ```bash
   git pull origin main
   nix run #build-switch
   ```

2. **플러그인 목록 공유**:
   - 필수 플러그인 목록을 팀 내에서 합의
   - 선택적 플러그인과 필수 플러그인 구분

3. **정기적인 환경 점검**:
   ```bash
   ./scripts/intellij-plugin-health-check
   ```

### 이슈 보고

플러그인 호환성 문제 발견 시:

1. 스크립트 실행 결과 공유
2. 사용 중인 플러그인 목록 제공
3. 에러 메시지 전체 내용 복사
4. IntelliJ IDEA 및 플러그인 버전 정보 포함
