# macOS 초기 설정 가이드

> **Apple Silicon/Intel Mac을 위한 완벽한 개발 환경 구성 가이드**

새로운 Mac을 받았거나 개발 환경을 처음부터 설정해야 하는 경우, 이 가이드를 따라 최적화된 개발 환경을 구성할 수 있습니다.

## 🎯 설정 목표

- **완전 자동화**: 한 번의 명령으로 모든 도구 설치
- **일관성 보장**: 모든 Mac에서 동일한 환경
- **개발 생산성**: 필수 도구와 최적화된 설정
- **보안 강화**: 1Password, 자동 잠금 등 보안 설정

## 📋 사전 준비사항

### 1. 시스템 요구사항

- **macOS 10.15 Catalina** 이상 (권장: macOS 13+)
- **관리자 권한** 필요
- **안정적인 인터넷 연결**
- **최소 5GB 여유 공간**

### 2. Apple 계정 설정

```bash
# App Store 로그인 확인
mas account
```

### 3. 기본 도구 설치

```bash
# Command Line Tools 설치 (최우선)
xcode-select --install

# 설치 확인
xcode-select -p
# 결과: /Applications/Xcode.app/Contents/Developer 또는 /Library/Developer/CommandLineTools
```

## 🚀 단계별 설정 과정

### 1단계: Nix 설치 및 설정

```bash
# Nix 설치 (Determinate Systems 권장)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# 새 터미널 세션 시작 또는 환경 다시 로드
source ~/.bashrc  # 또는 ~/.zshrc

# 설치 확인
nix --version
nix flake --help
```

### 2단계: Dotfiles 저장소 복제

```bash
# 저장소 복제
git clone https://github.com/your-username/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 사용자 환경 변수 설정
export USER=$(whoami)
echo "export USER=\$(whoami)" >> ~/.zshrc  # 또는 ~/.bashrc
```

### 3단계: 시스템 환경 적용

```bash
# 빌드 및 적용 (자동 sudo 처리)
nix run --impure .#build-switch

# 또는 단계별 실행
make build
make switch HOST=$(hostname)
```

### 4단계: 설치 확인 및 최종 설정

```bash
# 핵심 도구 설치 확인
which git zsh vim
brew --version
docker --version

# 시스템 상태 확인
make test
nix flake check --impure
```

## 🛠️ 설치되는 도구들

### 개발 도구

- **터미널**: iTerm2, Warp
- **에디터**: Vim, VS Code
- **버전 관리**: Git, GitHub CLI
- **컨테이너**: Docker, Kubernetes
- **개발 환경**: Node.js, Python, Go, Rust

### 생산성 도구

- **런처**: Alfred
- **창 관리**: Hammerspoon, Rectangle
- **패스워드**: 1Password + CLI
- **노트**: Obsidian, Notion
- **통신**: Slack, Discord, Telegram

### 브라우저

- **주요 브라우저**: Chrome, Firefox, Brave
- **개발 도구**: 각 브라우저의 DevTools

### 시스템 최적화

- **Alt-Tab**: 향상된 앱 스위칭
- **Karabiner-Elements**: 키보드 커스터마이징
- **Syncthing**: 파일 동기화

## ⚙️ 시스템 환경 설정

### 키보드 최적화

```bash
# 키 반복 속도 최적화 (이미 자동 설정됨)
defaults read NSGlobalDomain KeyRepeat        # 결과: 2
defaults read NSGlobalDomain InitialKeyRepeat # 결과: 15
```

### Dock 설정

```bash
# Dock 자동 숨김 및 크기 조정 (이미 자동 설정됨)
defaults read com.apple.dock autohide   # 결과: 1
defaults read com.apple.dock tilesize   # 결과: 48
```

### 트랙패드 설정

```bash
# 트랙패드 탭 클릭 활성화 (이미 자동 설정됨)
defaults read com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking # 결과: 1
```

## 🔧 개발 환경 커스터마이징

### 1. 패키지 추가

```bash
# 공통 패키지 추가
vim modules/shared/packages.nix

# macOS 전용 패키지 추가
vim modules/darwin/packages.nix

# Homebrew 앱 추가
vim modules/darwin/casks.nix
```

### 2. 셸 환경 설정

```bash
# Zsh 설정 커스터마이징
vim modules/shared/config/zsh/zshrc

# 별칭 추가
vim modules/shared/config/zsh/aliases.zsh
```

### 3. Hammerspoon 창 관리

```bash
# 창 관리 단축키 (이미 설정됨)
# Cmd+Shift+← : 왼쪽 절반으로 창 이동
# Cmd+Shift+→ : 오른쪽 절반으로 창 이동
# Cmd+Shift+↑ : 전체 화면
# Cmd+Shift+↓ : 중앙 정렬
```

### 4. 개발 프로젝트 생성

```bash
# 새 프로젝트 환경 생성
nix run .#setup-dev my-project

# 또는 글로벌 설치 후
./scripts/install-setup-dev
bl setup-dev my-project
```

## 🎨 테마 및 외관

### 터미널 테마

- **iTerm2**: 자동으로 Dark 테마 설정
- **색상 스키마**: One Dark Pro
- **폰트**: FiraCode Nerd Font

### 시스템 테마

```bash
# 다크 모드 활성화
osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true'

# 액센트 색상 설정 (선택사항)
defaults write NSGlobalDomain AppleAccentColor -int 1  # 그래파이트
```

## 🔐 보안 설정

### 1Password 설정

```bash
# 1Password 설치 확인
which op
op --version

# CLI 로그인 설정
op signin
```

### 시스템 보안

```bash
# 자동 잠금 설정 (15분)
sudo pmset -a displaysleep 15

# 방화벽 활성화
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
```

## 🚨 일반적인 문제 해결

### Xcode Command Line Tools 이슈

```bash
# 재설치가 필요한 경우
sudo xcode-select --reset
xcode-select --install
```

### Homebrew 권한 문제

```bash
# Homebrew 권한 수정
sudo chown -R $(whoami) /opt/homebrew
```

### 환경 변수 문제

```bash
# USER 변수 확인
echo $USER

# 미설정 시 수정
export USER=$(whoami)
echo "export USER=\$(whoami)" >> ~/.zshrc
```

## 📱 추가 권장 앱

### App Store 앱

```bash
# mas-cli로 자동 설치 (선택사항)
mas install 1333542190  # 1Password 7
mas install 497799835   # Xcode (필요한 경우)
```

### 수동 설치 권장 앱

- **Finder 대체**: Path Finder
- **텍스트 에디터**: Sublime Text, BBEdit
- **디자인**: Figma, Sketch
- **미디어**: IINA, Permute 3

## 🔄 정기 유지보수

### 매주 업데이트

```bash
# 시스템 업데이트
cd ~/dotfiles
nix flake update
make build && make switch HOST=$(hostname)

# Homebrew 업데이트
brew update && brew upgrade
```

### 매월 정리

```bash
# 캐시 정리
nix store gc
brew cleanup

# 시스템 정리
sudo pmset -g assertions  # 절전 모드 확인
```

## 🎯 성능 최적화

### 시스템 성능

```bash
# 메모리 압축 활성화
sudo sysctl vm.compressor_mode=4

# 부팅 시간 단축
sudo nvram SystemAudioVolume=" "
```

### 개발 성능

```bash
# Git 성능 향상
git config --global core.preloadindex true
git config --global core.fscache true

# 빌드 성능 향상
echo "max-jobs = auto" >> ~/.config/nix/nix.conf
```

## 📚 다음 단계

1. **문서 읽기**: `CLAUDE.md`에서 전체 시스템 가이드 확인
2. **개발 환경**: 프로젝트별 `setup-dev` 스크립트 활용
3. **자동화**: 개인 스크립트를 `~/.bl/commands/`에 추가
4. **보안**: SSH 키 생성 및 GitHub/GitLab 연결

## 🆘 도움 요청

- **문서**: `docs/TROUBLESHOOTING.md` 확인
- **GitHub Issues**: 버그 리포트 및 기능 요청
- **커뮤니티**: Nix 커뮤니티 참여

---

> **💡 팁**: 이 가이드를 따라 설정하면 30분 내에 완전한 개발 환경을 구성할 수 있습니다. 문제가 발생하면 `docs/TROUBLESHOOTING.md`를 먼저 확인하세요.
