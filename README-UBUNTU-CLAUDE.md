# Ubuntu Home Manager 설정 가이드

## 완료된 작업

1. ✅ **flake.nix 수정**: "ubuntu" 사용자를 commonUsers 목록에 추가
2. ✅ **Home Manager 빌드**: `nix build .#homeConfigurations.ubuntu.activationPackage --impure`
3. ✅ **구성 활성화**: `./result/activate`

## 신뢰할 수 없는 사용자 경고 해결

현재 여러 Nix 설정들이 무시되고 있습니다. 이를 해결하려면:

### 옵션 1: 사용자를 신뢰할 수 있는 사용자로 추가 (sudo 필요)
```bash
echo "trusted-users = ubuntu" | sudo tee -a /etc/nix/nix.conf
sudo systemctl restart nix-daemon  # 또는 시스템 재시작
```

### 옵션 2: Home Manager 전용 설정 사용 (권장)
현재 설정으로도 Home Manager는 정상 작동하며, 경고는 무시해도 됩니다.

## 빠른 빌드 및 적용

```bash
# 빌드 및 활성화 (한 줄로)
nix build .#homeConfigurations.ubuntu.activationPackage --impure && ./result/activate

# 또는 Makefile 사용 (향후 Ubuntu 지원 추가 예정)
make build-current  # 현재는 Darwin/NixOS만 지원
```

## 설치된 도구들

Home Manager를 통해 다음 도구들이 설치되었습니다:
- zsh (powerlevel10k 테마 포함)
- git (설정 포함)
- vim (플러그인 포함)
- tmux (플러그인 포함)
- fzf
- direnv
- jq
- 기타 유용한 CLI 도구들

## 다음 단계

1. 새 터미널을 열어 zsh 및 설정이 적용되었는지 확인
2. 필요시 기본 셸을 zsh로 변경: `chsh -s $(which zsh)`
3. `~/.config/` 디렉토리에 생성된 설정 파일들 확인

## 문제 해결

- **빌드 실패**: `--impure` 플래그 확인
- **활성화 실패**: 홈 디렉토리 권한 확인
- **경고 메시지**: 대부분 무시 가능, 기능에는 영향 없음
