# macOS 15 (Sequoia) 트러블슈팅 가이드

> **macOS 15 Sequoia 전용 문제 해결 가이드 - 새로운 보안 정책과 시스템 변경사항 대응**

macOS 15 Sequoia는 강화된 보안 정책과 시스템 변경으로 인해 기존 개발 환경에서 새로운 문제들이 발생할 수 있습니다. 이 가이드는 macOS 15에서 발생하는 구체적인 문제들과 해결 방법을 제공합니다.

## 🚨 macOS 15 주요 변경사항

### 보안 강화
- **Gatekeeper 정책 강화**: 서명되지 않은 앱 실행 제한
- **SIP 확장**: 시스템 무결성 보호 범위 확대
- **App Transport Security**: 네트워크 보안 요구사항 강화
- **Private Network Access**: 로컬 네트워크 접근 제한

### 시스템 변경사항
- **Homebrew 경로 변경**: `/opt/homebrew` 고정화
- **Python 버전 업데이트**: 기본 Python 3.12
- **Node.js 호환성**: 일부 네이티브 모듈 재컴파일 필요
- **Xcode 16**: 새로운 빌드 도구체인

## 🛠️ 설치 관련 문제

### 1. Command Line Tools 설치 실패

**증상:**
```bash
$ xcode-select --install
xcode-select: error: command line tools are already installed
# 하지만 실제로는 제대로 설치되지 않음
```

**해결방법:**
```bash
# 기존 설치 제거
sudo rm -rf /Library/Developer/CommandLineTools

# 재설치
xcode-select --install

# 또는 전체 Xcode 설치
mas install 497799835  # Xcode from App Store

# 설치 확인
xcode-select -p
gcc --version
```

### 2. Homebrew 설치 권한 문제

**증상:**
```bash
$ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
Error: Permission denied - /opt/homebrew
```

**해결방법:**
```bash
# 권한 확인
ls -la /opt/

# 디렉토리 생성 및 권한 설정
sudo mkdir -p /opt/homebrew
sudo chown -R $(whoami):admin /opt/homebrew

# Homebrew 재설치
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# PATH 설정 확인
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### 3. Nix 설치 실패 (T2/M-series 칩 관련)

**증상:**
```bash
$ curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
error: Nix daemon failed to start
```

**해결방법:**
```bash
# 기존 설치 완전 제거
sudo /nix/uninstall

# 시스템 재부팅
sudo reboot

# 재설치 전 SIP 상태 확인
csrutil status

# SIP가 활성화된 경우 Determinate Systems 설치 권장
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --determinate

# 데몬 수동 시작
sudo launchctl load /Library/LaunchDaemons/org.nixos.nix-daemon.plist

# 설치 확인
nix --version
```

## 🔐 보안 관련 문제

### 1. 앱 서명 문제 (개발 도구)

**증상:**
```bash
"MyApp.app" cannot be opened because the developer cannot be verified.
```

**해결방법:**
```bash
# 개별 앱 허용
sudo xattr -rd com.apple.quarantine /Applications/MyApp.app

# 또는 시스템 전체 Gatekeeper 임시 비활성화
sudo spctl --master-disable

# 설치 후 다시 활성화
sudo spctl --master-enable

# 특정 앱 서명 확인
spctl -a -t exec -vv /Applications/MyApp.app
```

### 2. 로컬 네트워크 접근 제한

**증상:**
```bash
# Docker 컨테이너 접근 불가
curl: (7) Failed to connect to localhost port 3000: Connection refused
```

**해결방법:**
```bash
# 시스템 환경설정에서 허용
# System Preferences → Security & Privacy → Privacy → Local Network
# 해당 앱들을 허용 목록에 추가

# 또는 방화벽 규칙 추가
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /Applications/Docker.app
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblock /Applications/Docker.app
```

### 3. 터미널 앱 권한 문제

**증상:**
```bash
# 파일 접근 거부
Operation not permitted: ~/Documents/my-file.txt
```

**해결방법:**
```bash
# 시스템 환경설정에서 권한 부여
# System Preferences → Security & Privacy → Privacy → Full Disk Access
# Terminal.app, iTerm.app 등 추가

# 또는 명령줄로 확인
tccutil reset All com.apple.Terminal
```

## 🧪 개발 환경 문제

### 1. Python 호환성 문제

**증상:**
```bash
$ python3 -m pip install numpy
error: Microsoft Visual C++ 14.0 is required
```

**해결방법:**
```bash
# Python 3.12 호환성 확인
python3 --version  # 3.12.x

# 가상환경 생성
python3 -m venv venv
source venv/bin/activate

# 업데이트된 패키지 설치
pip install --upgrade pip setuptools wheel
pip install numpy

# 또는 Nix로 Python 환경 관리
nix-shell -p python312 python312Packages.numpy
```

### 2. Node.js 네이티브 모듈 문제

**증상:**
```bash
$ npm install
node-pre-gyp ERR! build error 
node-pre-gyp ERR! stack Error: Failed to execute 'node-gyp build'
```

**해결방법:**
```bash
# Node.js 버전 확인
node --version

# 네이티브 모듈 재빌드
npm rebuild

# 또는 Python 경로 명시적 설정
npm config set python /usr/bin/python3
npm install --build-from-source

# Xcode 빌드 도구 경로 확인
xcode-select -p
```

### 3. Docker Desktop 호환성

**증상:**
```bash
$ docker run hello-world
docker: Cannot connect to the Docker daemon at unix:///var/run/docker.sock
```

**해결방법:**
```bash
# Docker Desktop 최신 버전 확인
docker --version

# 권한 확인
sudo usermod -aG docker $(whoami)

# 서비스 재시작
killall Docker && open /Applications/Docker.app

# 또는 네트워크 권한 허용
# System Preferences → Security & Privacy → Privacy → Local Network
# Docker 체크

# Homebrew로 재설치
brew install --cask docker
```

## 🔧 빌드 및 컴파일 문제

### 1. Xcode 16 빌드 도구 문제

**증상:**
```bash
$ make build
error: SDK does not contain 'libarclite' at the path '/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/arc/libarclite_macosx.a'
```

**해결방법:**
```bash
# Xcode 16 호환성 확인
xcodebuild -version

# 빌드 설정 업데이트
export MACOSX_DEPLOYMENT_TARGET=13.0
export XCODE_VERSION=16.0

# 또는 Command Line Tools 명시적 사용
sudo xcode-select --switch /Library/Developer/CommandLineTools

# 빌드 재시도
make build
```

### 2. 아키텍처 불일치 문제

**증상:**
```bash
$ make build
ld: symbol(s) not found for architecture arm64
```

**해결방법:**
```bash
# 아키텍처 확인
uname -m  # arm64 또는 x86_64

# Rosetta 2 설치 (Apple Silicon에서 Intel 바이너리 실행)
softwareupdate --install-rosetta --agree-to-license

# 아키텍처별 빌드 설정
export ARCHFLAGS="-arch arm64"  # Apple Silicon
export ARCHFLAGS="-arch x86_64"  # Intel

# 또는 Universal Binary 빌드
export ARCHFLAGS="-arch arm64 -arch x86_64"
```

## 🌐 네트워크 및 인증 문제

### 1. GitHub 인증 문제

**증상:**
```bash
$ git push origin main
remote: Support for password authentication was removed on August 13, 2021.
```

**해결방법:**
```bash
# GitHub CLI 설치 및 로그인
brew install gh
gh auth login

# 또는 Personal Access Token 사용
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# SSH 키 생성 및 등록
ssh-keygen -t ed25519 -C "your.email@example.com"
eval "$(ssh-agent -s)"
ssh-add --apple-use-keychain ~/.ssh/id_ed25519

# GitHub에 공개키 등록
gh ssh-key add ~/.ssh/id_ed25519.pub
```

### 2. 프록시 환경 문제

**증상:**
```bash
$ nix build
error: unable to download 'https://cache.nixos.org/...'
```

**해결방법:**
```bash
# 프록시 설정 확인
echo $http_proxy
echo $https_proxy

# 회사 프록시 설정
export http_proxy=http://proxy.company.com:8080
export https_proxy=http://proxy.company.com:8080

# Nix 설정에 프록시 추가
mkdir -p ~/.config/nix
echo "http-proxy = http://proxy.company.com:8080" >> ~/.config/nix/nix.conf
echo "https-proxy = http://proxy.company.com:8080" >> ~/.config/nix/nix.conf
```

## 📱 GUI 앱 관련 문제

### 1. Homebrew Cask 설치 실패

**증상:**
```bash
$ brew install --cask google-chrome
Error: It seems there is already an App at '/Applications/Google Chrome.app'
```

**해결방법:**
```bash
# 기존 앱 제거
rm -rf "/Applications/Google Chrome.app"

# 캐시 정리
brew cleanup

# 재설치
brew install --cask google-chrome

# 또는 강제 설치
brew install --cask google-chrome --force
```

### 2. 앱 실행 시 권한 요청 반복

**증상:**
```
"MyApp" would like to access files in your Documents folder.
# 매번 권한 요청이 나타남
```

**해결방법:**
```bash
# 권한 데이터베이스 초기화
sudo tccutil reset All

# 또는 특정 앱 권한 초기화
sudo tccutil reset All com.company.myapp

# 시스템 환경설정에서 수동으로 권한 부여
# System Preferences → Security & Privacy → Privacy
# 각 카테고리에서 앱 권한 설정
```

## 🎯 성능 및 리소스 문제

### 1. 메모리 사용량 급증

**증상:**
```bash
$ top
# 메모리 사용량이 90% 이상
```

**해결방법:**
```bash
# 메모리 사용량 확인
memory_pressure
vm_stat

# 메모리 압축 최적화
sudo sysctl vm.compressor_mode=4

# 백그라운드 앱 정리
launchctl list | grep -v com.apple
sudo launchctl unload /Library/LaunchDaemons/unnecessary.plist

# 또는 시스템 재부팅
sudo reboot
```

### 2. 디스크 공간 부족

**증상:**
```bash
$ df -h
/dev/disk1 98% full
```

**해결방법:**
```bash
# 큰 파일 찾기
du -h -d 1 ~ | sort -hr | head -20

# Nix 스토어 정리
nix store gc
nix store optimise

# Homebrew 정리
brew cleanup --prune=all

# 시스템 캐시 정리
sudo rm -rf /var/log/*
sudo rm -rf ~/Library/Caches/*
```

## 🔍 진단 및 모니터링

### 시스템 상태 확인

```bash
# 시스템 정보
system_profiler SPSoftwareDataType
system_profiler SPHardwareDataType

# 보안 상태
csrutil status  # SIP 상태
spctl --status  # Gatekeeper 상태

# 네트워크 상태
networksetup -listallhardwareports
ping -c 4 8.8.8.8

# 프로세스 모니터링
ps aux | head -20
top -o cpu
```

### 로그 분석

```bash
# 시스템 로그
log show --predicate 'process == "WindowServer"' --info --last 1h

# 설치 로그
log show --predicate 'process == "Installer"' --info --last 1h

# 네트워크 로그
log show --predicate 'category == "networking"' --info --last 30m
```

## 🚀 macOS 15 최적화 팁

### 성능 최적화

```bash
# 애니메이션 속도 향상
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

# 키보드 반응 속도 최적화
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 10

# Dock 반응 속도 최적화
defaults write com.apple.dock autohide-time-modifier -float 0.5
defaults write com.apple.dock autohide-delay -float 0.1
killall Dock
```

### 개발 환경 최적화

```bash
# Git 성능 향상
git config --global core.preloadindex true
git config --global core.fscache true
git config --global gc.auto 256

# 터미널 성능 향상
echo "export HISTSIZE=10000" >> ~/.zshrc
echo "export SAVEHIST=10000" >> ~/.zshrc
echo "setopt HIST_EXPIRE_DUPS_FIRST" >> ~/.zshrc
```

## 📞 추가 지원

### Apple 지원 연락처
- **Apple Support**: 1-800-APL-CARE
- **Developer Support**: https://developer.apple.com/support/
- **온라인 지원**: https://support.apple.com/

### 커뮤니티 리소스
- **Stack Overflow**: macOS 15 태그
- **Reddit**: r/macOSBigSur, r/MacOS
- **Discord**: macOS 개발자 커뮤니티

---

> **💡 중요**: macOS 15는 아직 새로운 시스템이므로 일부 써드파티 앱이나 도구가 완전히 호환되지 않을 수 있습니다. 문제가 지속되면 해당 도구의 공식 지원을 받거나 대안을 찾아보세요.