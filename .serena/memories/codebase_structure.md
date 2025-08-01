# 코드베이스 구조

## 디렉토리 구조

```
├── flake.nix              # Flake 진입점 및 출력 정의
├── Makefile               # 개발 워크플로 자동화
├── CLAUDE.md              # Claude Code 프로젝트 지침
├── CONTRIBUTING.md        # 개발 가이드라인 및 표준
│
├── modules/               # 모듈화된 설정 시스템
│   ├── shared/            #   크로스 플랫폼 설정
│   ├── darwin/            #   macOS 전용 모듈
│   └── nixos/             #   NixOS 전용 모듈
│
├── hosts/                 # 호스트별 설정
│   ├── darwin/            #   macOS 시스템 정의
│   └── nixos/             #   NixOS 시스템 정의
│
├── lib/                   # Nix 유틸리티 함수 및 빌더
├── scripts/               # 자동화 및 관리 도구
├── tests/                 # 다계층 테스트 프레임워크
├── docs/                  # 포괄적인 문서
├── config/                # 외부화된 설정 파일
└── overlays/              # 커스텀 패키지 정의 및 패치
```

## 모듈 계층

1. **플랫폼 모듈** (`modules/{darwin,nixos}/`): OS별 설정
2. **공유 모듈** (`modules/shared/`): 크로스 플랫폼 기능 제공
3. **호스트 설정** (`hosts/`): 개별 머신 설정 정의
4. **라이브러리 함수** (`lib/`): 재사용 가능한 Nix 유틸리티

## 주요 파일

- `flake.nix`: 시스템 진입점
- `Makefile`: 개발 명령어 인터페이스
- `modules/shared/lib/claude-activation.nix`: Claude Code 활성화 로직
- `tests/`: 테스트 스위트 (unit, integration, e2e, performance)