# 시스템 유틸리티 (macOS Darwin)

## 기본 명령어

### 파일 시스템
- `ls` - 파일 목록 (macOS BSD 버전)
- `find` - 파일 검색 (BSD find 사용)
- `grep` - 텍스트 검색 (BSD grep, 또는 GNU grep 설치 시)
- `cd` - 디렉토리 변경

### Git 명령어
- `git status` - 워킹 트리 상태
- `git diff` - 변경사항 확인
- `git commit` - 커밋 생성
- `git push` - 원격 저장소로 푸시

### 시스템 정보
- `uname -s` - 운영체제 이름 (Darwin)
- `uname -m` - 아키텍처 (x86_64 또는 arm64)
- `whoami` - 현재 사용자

### 권한 관리
- `sudo` - 관리자 권한으로 실행
- `chmod` - 파일 권한 변경

## 프로젝트별 유틸리티

### Nix 명령어
- `nix` - Nix 패키지 매니저 (실험적 기능 포함)
- `nix-instantiate` - Nix 표현식 평가
- `nix-store` - Nix 스토어 관리

### 개발 도구
- `make` - Makefile 기반 빌드 도구
- `pre-commit` - Git hook 관리
- `bash` - 스크립트 실행

## macOS 특화 명령어

### 시스템 관리
- `brew` - Homebrew 패키지 매니저 (GUI 앱용)
- `launchctl` - 시스템 서비스 관리
- `defaults` - 시스템 설정 관리

### 네트워크
- `curl` - HTTP 클라이언트
- `ssh` - 보안 셸

## 환경 변수

### 필수 환경 변수
```bash
export USER=$(whoami)    # 사용자 이름 (필수)
```

### 선택적 환경 변수
```bash
export CI_MODE=local     # CI와 동일한 환경
export CACHE_MAX_SIZE_GB=10
export HTTP_CONNECTIONS=100
```