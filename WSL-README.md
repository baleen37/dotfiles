# WSL+NixOS 환경에서 baleen37/dotfiles 적용 가이드

## 🎯 개요

이 가이드는 WSL(Windows Subsystem for Linux) + NixOS 환경에서 baleen37/dotfiles의 기능을 부분적으로 적용하는 실용적인 해결책을 제공합니다.

## 🔍 현재 환경

- **사용자**: `nixos`
- **호스트**: `nixos` (WSL 환경)
- **Nix 버전**: 2.32.2
- **시스템**: 이미 NixOS로 전체 구성됨

## 🛠️ 해결책 요약

### 1. 즉시 시도 가능한 방법

#### 방법 A: 전체 자동 적용 스크립트
```bash
# 전체 기능 한 번에 적용
./scripts/wsl-nixos-apply.sh
```

#### 방법 B: 선택적 기능 적용
```bash
# 대화형으로 기능 선택
./scripts/selective-feature-apply.sh
```

### 2. 수동 환경 설정

#### 환경 변수 설정
```bash
export USER=nixos
export EDITOR=vim
export VISUAL=vim
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# PATH 설정 (dotfiles 스타일)
export PATH=$HOME/.npm-global/bin:$HOME/.npm-packages/bin:$HOME/bin:$PATH
export PATH=$HOME/.local/share/bin:$HOME/.local/bin:$PATH
export PATH=$HOME/.cargo/bin:$HOME/go/bin:$PATH
```

#### 필수 패키지 확인
```bash
# 설치된 패키지 확인
which git vim zsh fzf fd bat tree curl wget jq ripgrep

# 누락된 패키지는 NixOS configuration.nix에 추가
```

## 📁 파일 구조

### 스크립트 파일
- `scripts/wsl-nixos-apply.sh` - 전체 자동 적용
- `scripts/selective-feature-apply.sh` - 선택적 기능 적용
- `WSL-README.md` - 이 가이드

### 적용되는 설정
- `~/.zshrc` - Zsh 설정 (dotfiles 기반)
- `~/.vimrc` - Vim 설정
- `~/.gitconfig` - Git 설정
- `~/.claude/` - Claude Code 설정 (연결)

## 🚀 단계별 적용 절차

### 단계 1: 기본 준비
```bash
# dotfiles 디렉토리 확인
cd ~/dotfiles
ls -la scripts/

# 스크립트 실행 권한 확인
ls -l scripts/*.sh
```

### 단계 2: 전체 적용 (권장)
```bash
# 전체 기능 적용
./scripts/wsl-nixos-apply.sh

# 결과 확인
ls -la ~/.zshrc ~/.vimrc ~/.gitconfig
```

### 단계 3: Zsh로 전환
```bash
# Zsh가 기본 셸이 되도록 설정
chsh -s $(which zsh)

# 또는 현재 세션에서만 Zsh 사용
zsh
```

### 단계 4: Vim 플러그인 설치
```bash
# Vim 실행
vim

# 플러그인 설치 명령
:PlugInstall
:q
```

## ✅ 성공 확인 방법

### 1. 셸 환경 확인
```bash
# Zsh 설정 로드
source ~/.zshrc

# 알리아스 확인
alias | grep -E "(ga|gc|gs|la|ll)"

# FZF 동작 확인
Ctrl+T (파일 검색)
Ctrl+R (히스토리 검색)
```

### 2. Git 설정 확인
```bash
git config --list --global

# 사용자 정보 확인
git config --global user.name
git config --global user.email
```

### 3. Vim 설정 확인
```bash
vim --version | head -3

# Vim에서 설정 확인
vim -c "set number? set tabstop? set expandtab?"
```

### 4. 개발 환경 확인
```bash
# PATH 확인
echo $PATH | tr ':' '\n' | grep -E "(npm|cargo|go)"

# Nix 함수 확인
which shell
shell --help 2>/dev/null || echo "shell 함수는 nix-shell 필요"
```

### 5. Claude Code 설정 확인 (설치된 경우)
```bash
if command -v claude &> /dev/null; then
    claude --version
    which cc  # 단축키 확인
else
    echo "Claude CLI 설치 안됨"
fi
```

## 🔧 기능별 설명

### 🔧 개발 도구 (기본)
- Git 기본 설정
- Vim 기본 설정
- 기본 알리아스 (`la`, `ll`, `ls`)

### 🐚 Shell 환경 (고급)
- Zsh + FZF 통합
- Git 알리아스 (`ga`, `gc`, `gs`, `gl`)
- Nix 단축 함수 (`shell`)
- SSH 개선 wrapper

### 📝 편집기 설정
- vim-plug 플러그인 매니저
- FZF, NERDTree, Git 통합
- Gruvbox 테마
- 자동완성 및 문법 강조

### 🌐 Git 설정
- baleen37 스타일 설정
- 전역 알리아스
- 브랜치 기본 설정

### 🤖 Claude Code 통합
- 설정 파일 연결
- CLI 단축키 (`cc`)
- 스킬 및 명령어 설정

### 📦 개발 환경
- 다양한 언어 PATH 설정
- npm, cargo, go 지원
- 개발 도우미 알리아스

## 🚨 주의사항

### 제한 사항
1. **시스템 전체 설정**: NixOS 시스템 설정은 `/etc/nixos/configuration.nix`에서 관리
2. **패키지 설치**: 전역 패키지는 `sudo nixos-rebuild switch` 필요
3. **Home Manager**: 버전 호환성 문제로 독립 실행 모드 사용 불가

### 호환성
- ✅ Zsh 설정 (대부분 호환)
- ✅ Vim 설정 (완전 호환)
- ✅ Git 설정 (완전 호환)
- ✅ 환경 변수 (WSL 최적화 포함)
- ⚠️ 일부 macOS 전용 기능 제외
- ❌ Homebrew 관련 설정 (WSL에서 불필요)

### 백업
- 모든 기존 설정은 `*.backup` 파일로 백업됨
- 문제 발생 시 백업 파일에서 복원 가능

## 🔄 문제 해결

### 공통 문제
```bash
# 설정 다시 로드
source ~/.zshrc

# 백업에서 복원
cp ~/.zshrc.backup ~/.zshrc

# 권한 문제
chmod 644 ~/.zshrc ~/.vimrc
```

### 패키지 관련
```bash
# 패키지 설치 상태 확인
nix-store -q --references /run/current-system/sw | grep -E "(git|vim|zsh)"

# 필요한 패키지가 없을 경우 configuration.nix에 추가
# (sudo 권한 필요)
```

### WSL 특화 문제
```bash
# Windows-Unix 경로 변환 테스트
wslpath -w /home/nixos
wslpath -u "C:\\Users"

# PATH 문제 해결
echo $PATH | tr ':' '\n'
```

## 📞 지원

- **문제 보고**: GitHub Issues 사용
- **설정 위치**: `~/dotfiles/scripts/`
- **백업 위치**: `~/.zshrc.backup`, `~/.vimrc.backup`
- **로그 위치**: 실행 시 터미널 출력 확인

---

## 🎉 마무리

이 가이드를 통해 WSL+NixOS 환경에서 baleen37/dotfiles의 핵심 기능을 성공적으로 적용할 수 있습니다. 전체 시스템 재구성 없이 사용자 환경만 개선하여 개발 생산성을 높일 수 있습니다.