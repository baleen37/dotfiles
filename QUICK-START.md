# WSL+NixOS에서 baleen37/dotfiles 빠른 시작 가이드

## 🚀 30초 만에 시작하기

### 방법 1: 전체 자동 적용 (권장)
```bash
cd ~/dotfiles
./scripts/wsl-nixos-apply-fixed.sh
```

### 방법 2: 선택적 기능 적용
```bash
cd ~/dotfiles
./scripts/selective-feature-apply.sh
```

### 방법 3: 최소한의 설정만
```bash
# Zsh로 전환
chsh -s $(which zsh)

# 기본 설정 복사
cp ~/dotfiles/scripts/minimal-setup.sh ~/
./minimal-setup.sh
```

---

## ✅ 적용 즉시 확인하기

```bash
# 1. Zsh 실행
zsh

# 2. 알리아스 확인
alias | grep -E "(ga|gc|la)"

# 3. FZF 테스트 (설치된 경우)
fzf

# 4. Git 설정 확인
git config --list --global | head -5

# 5. 도우미 스크립트 확인
~/nixos-dotfiles-helper.sh info
```

---

## 🎯 주요 기능

### 바로 사용 가능
- ✅ **Zsh + 알리아스**: `ga`, `gc`, `gs`, `la`, `ll`
- ✅ **FZF 통합**: `Ctrl+T` (파일 검색), `Ctrl+R` (히스토리)
- ✅ **Vim 설정**: 자동 들여쓰기, 줄 번호, 문법 강조
- ✅ **환경 변수**: 개발 도구 PATH 설정
- ✅ **WSL 최적화**: Windows-Unix 경로 변환

### 설정 필요
- ⚠️ **Git 사용자 정보**: 수동 설정 필요
- ⚠️ **누락된 패키지**: NixOS configuration.nix에 추가
- ⚠️ **Vim 플러그인**: vim-plug 설치 필요

---

## 🛠️ 문제 해결

### Git 설정 문제
```bash
# 관리자 권한으로 Git 설정
sudo git config --system user.name "Your Name"
sudo git config --system user.email "your.email@example.com"
```

### 패키지 설치 문제
```bash
# configuration.nix에 패키지 추가 (관리자 권한 필요)
# environment.systemPackages = with pkgs; [ git vim zsh fzf fd bat ];
# 그리고: sudo nixos-rebuild switch
```

### 설정 초기화
```bash
# 백업에서 복원
cp ~/.zshrc.backup ~/.zshrc
cp ~/.vimrc.backup ~/.vimrc
```

---

## 📁 주요 파일 위치

| 파일 | 목적 | 백업 위치 |
|------|------|-----------|
| `~/.zshrc` | Zsh 설정 | `~/.zshrc.backup` |
| `~/.vimrc` | Vim 설정 | `~/.vimrc.backup` |
| `~/nixos-dotfiles-helper.sh` | 도우미 스크립트 | - |
| `~/dotfiles/` | 원본 dotfiles | - |

---

## 🎉 성공 확인 체크리스트

- [ ] `zsh` 실행 후 프롬프트 변경됨
- [ ] `ga` 입력시 `git add` 동작함
- [ ] `la` 입력시 파일 목록 보임
- [ ] `fzf` 실행시 퍼지 검색 동작함 (설치된 경우)
- [ ] `vim` 실행시 줄 번호 표시됨
- [ ] `~/nixos-dotfiles-helper.sh info` 실행시 정보 출력됨

---

## 🆘 도움이 필요한가요?

1. **전체 가이드**: `WSL-README.md` 참조
2. **문제 보고**: GitHub Issues
3. **설정 위치**: `~/dotfiles/scripts/`