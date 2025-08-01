# 프로젝트 목적

이 저장소는 **Professional Nix Dotfiles System**으로, macOS와 NixOS에서 재현 가능한 개발 환경을 제공하는 엔터프라이즈급 dotfiles 관리 시스템입니다.

## 핵심 기능

- **크로스 플랫폼 호환성**: macOS (Intel + Apple Silicon)와 NixOS (x86_64 + ARM64) 네이티브 지원
- **모듈화된 아키텍처**: 플랫폼별 및 공유 설정의 명확한 분리
- **포괄적인 테스트**: 단위, 통합, 엔드투엔드, 성능 테스트 스위트
- **Claude Code 통합**: 20+ 전문 명령어를 제공하는 AI 기반 개발 지원
- **고급 자동화**: 자동 업데이트 시스템, 설정 보존, 지능형 빌드 최적화

## 주요 구성 요소

- **50+ 개발 도구**: git, vim, docker, terraform, nodejs, python 등 포괄적인 툴체인
- **Homebrew 통합**: macOS에서 34+ GUI 애플리케이션을 선언적으로 관리
- **글로벌 명령 시스템**: 프로젝트 간 개발 작업을 위한 `bl` 디스패처
- **품질 보증 프레임워크**: 다계층 테스트 및 CI/CD 파이프라인