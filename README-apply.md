# 💡 간단한 적용 방법

## Claude Code에서 빌드 후 터미널에서 적용

### 1단계: Claude Code에서 빌드
```bash
make build
```

### 2단계: 터미널에서 간단 적용
```bash
./apply.sh
```

또는

```bash
make apply
```

## 🔧 TouchID sudo 설정 (한 번만)

터미널에서 실행:
```bash
sudo cp /etc/pam.d/sudo_local.template /etc/pam.d/sudo_local
```

설정 후 `make apply`가 지문으로 작동합니다.

## 📁 파일 구조

- `make build` - Claude Code에서 안전하게 빌드
- `apply.sh` - 터미널에서 간단 적용
- `make apply` - 빌드 확인 후 적용

**관리 포인트 최소화**: 빌드와 적용 완전 분리!