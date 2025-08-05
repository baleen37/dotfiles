# /nix - Nix 시스템 전용

dotfiles Nix 환경 전문 관리

## 사용법
```bash
/nix [operation] [--build|--switch|--update]
```

## 자동 시스템
- **nix-system-expert** 전문가 자동 활성화
- **크로스 플랫폼**: macOS (Intel/ARM) + NixOS 자동 감지
- **Flake 최적화**: 빌드 캐시, 병렬 처리, 성능 최적화

## 주요 작업
- `--build` - Nix 빌드 (현재 플랫폼)
- `--switch` - 빌드 + 적용 (sudo 필요)
- `--update` - Flake 업데이트 + 빌드

## Nix 전문 영역
- **Flakes**: flake.nix, inputs, outputs 관리
- **Home Manager**: 사용자 환경 설정
- **nix-darwin**: macOS 시스템 설정  
- **모듈 시스템**: shared, darwin, nixos 모듈
- **성능 최적화**: 빌드 시간, 캐시 효율성

## 자동 감지
- **플랫폼**: Darwin vs NixOS 자동 구분
- **아키텍처**: Intel vs ARM 자동 감지
- **모듈 의존성**: 변경 영향도 분석
- **빌드 최적화**: 필요한 부분만 재빌드

## 일반적인 작업
```bash
/nix --build                # 현재 시스템 빌드
/nix --switch              # 빌드 후 시스템 적용
/nix --update              # Flake 업데이트

# 문제 해결
/nix "빌드 에러 해결" --build
/nix "모듈 추가" --switch

# 성능 최적화  
/nix "빌드 시간 개선" --build --think
```

## dotfiles 특화
- **Makefile 통합**: `make switch` 등과 연동
- **USER 변수**: `export USER=$(whoami)` 자동 설정
- **성능 모니터링**: 빌드 시간, 메모리 사용량 추적
- **모듈 아키텍처**: lib/platform-system.nix 활용
