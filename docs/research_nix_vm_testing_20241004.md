# Nix 경량 VM 테스팅 솔루션 연구

## Executive Summary

Nix 테스트를 위한 경량 VM 환경으로는 **NixOS 내장 테스트 프레임워크 (QEMU)**, **microVM.nix (Firecracker)**, **nixos-shell**, **NixOS 컨테이너 (systemd-nspawn)** 등이 있습니다. 각 솔루션은 용도와 요구사항에 따라 선택할 수 있습니다.

## 1. NixOS Test Framework (QEMU) ⭐ 권장

### 특징

- **초경량**: `/nix/store`를 VM에 직접 마운트하여 추가 이미지 오버헤드 없음
- **빠른 실행**: VM 설정 및 종료 포함 약 10초 소요
- **최소 오버헤드**: headless QEMU VM으로 리소스 사용 최소화
- **macOS 지원**: 2024년 3월부터 macOS에서도 NixOS 테스트 실행 가능 (Linux builder 필요)

### macOS 지원 상세

**2024년 3월 업데이트**: Gabriella Gonzalez가 macOS에서 NixOS integration test를 실행할 수 있도록 nixpkgs에 기여했습니다.

#### 요구사항

1. **Linux Builder**: nix-darwin의 `linux-builder` 기능 활성화 필요
2. **Nix 2.19+**: `nixos-test`와 `apple-virt` capability 자동 감지
3. **시스템 설정**: nix-darwin 설정 필요

#### nix-darwin 설정 예제

```nix
# hosts/darwin/default.nix
{
  nix.linux-builder.enable = true;
  nix.settings.system-features = [
    "nixos-test"
    "apple-virt"
  ];
}
```

#### 적용 및 확인

```bash
# nix-darwin 적용
darwin-rebuild switch --flake .#

# 설정 확인
nix show-config system-features
sudo launchctl list org.nixos.linux-builder
```

#### 제약사항

- **M1/M2/M3**: nested virtualization 미지원으로 Linux builder 내에서 추가 VM 실행 불가
- **성능**: macOS에서 실행 시 Linux 네이티브 대비 약간 느림 (개선 중)
- **아키텍처**: VM은 여전히 Linux VM이지만, QEMU와 Python 드라이버는 macOS 네이티브 실행

### Flake 예제

```nix
{
  description = "NixOS VM test example";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

  outputs = { self, nixpkgs }: {
    checks.x86_64-linux.myTest = nixpkgs.lib.nixos.runTest {
      name = "my-test";
      nodes.machine = { pkgs, ... }: {
        services.nginx.enable = true;
        networking.firewall.allowedTCPPorts = [ 80 ];
      };

      testScript = ''
        machine.wait_for_unit("nginx.service")
        machine.wait_for_open_port(80)
        machine.succeed("curl http://localhost")
      '';
    };
  };
}
```

### 실행 방법

```bash
# 테스트 실행
nix flake check

# 인터랙티브 디버깅
nix build .#checks.x86_64-linux.myTest.driverInteractive
./result/bin/nixos-test-driver --interactive
```

## 2. microVM.nix (Firecracker/QEMU)

### 특징

- **Firecracker 지원**: 125ms 시작 시간, 5MB 메모리 사용
- **다중 하이퍼바이저**: QEMU, Firecracker, Cloud Hypervisor, crosvm 등 지원
- **고정 RAM 할당**: 기본 512MB (조절 가능)

### Flake 예제

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    microvm = {
      url = "github:astro/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, microvm }: {
    nixosConfigurations.my-microvm = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        microvm.nixosModules.microvm
        {
          microvm = {
            hypervisor = "qemu";  # 또는 "firecracker"
            mem = 256;  # MB
            vcpu = 1;
          };

          services.nginx.enable = true;
        }
      ];
    };
  };
}
```

### 실행 방법

```bash
# QEMU로 실행
nix run microvm#qemu-example

# Firecracker로 실행 (더 빠름)
nix run microvm#firecracker-example
```

## 3. nixos-shell

### 특징

- **간단한 설정**: 현재 디렉토리의 `vm.nix` 파일 사용
- **홈 디렉토리 마운트**: 개발 환경 공유
- **콘솔 접근**: 동일 터미널에서 바로 접근

### 사용 예제

```nix
# vm.nix
{ pkgs, ... }: {
  services.nginx.enable = true;

  # 포트 포워딩
  virtualisation.forwardPorts = [{
    from = "host";
    host.port = 8080;
    guest.port = 80;
  }];
}
```

### 실행 방법

```bash
# nixos-shell 설치 및 실행
nix-shell -p nixos-shell
nixos-shell

# Flake 사용
nixos-shell --flake .#myVM
```

## 4. NixOS Containers (systemd-nspawn)

### 특징

- **최경량**: VM보다 적은 리소스 사용
- **systemd 통합**: `systemctl`로 관리
- **Docker 불필요**: 별도 데몬 없이 동작

### Configuration 예제

```nix
# /etc/nixos/configuration.nix
{
  containers.myapp = {
    autoStart = true;
    config = { pkgs, ... }: {
      services.nginx.enable = true;
      networking.firewall.allowedTCPPorts = [ 80 ];
    };
  };
}
```

### 관리 명령

```bash
# 컨테이너 시작/중지
systemctl start container@myapp
systemctl stop container@myapp

# 컨테이너 접근
machinectl login myapp
```

## 5. Podman (OCI 컨테이너)

### 특징

- **Docker 호환**: 명령어 그대로 사용 가능
- **Daemonless**: 백그라운드 서비스 불필요
- **보안**: rootless 모드 지원

### NixOS 설정

```nix
{
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };
}
```

## 추천 시나리오별 선택

### 단위 테스트/CI

**NixOS Test Framework (QEMU)**

- 이유: 빠른 실행, 재현 가능한 테스트 환경

### 마이크로서비스 개발

**microVM.nix + Firecracker**

- 이유: 초고속 부팅, 최소 메모리 사용

### 로컬 개발 테스트

**nixos-shell**

- 이유: 간단한 설정, 홈 디렉토리 공유

### 서비스 격리

**NixOS Containers**

- 이유: 최소 오버헤드, systemd 통합

### Docker 마이그레이션

**Podman**

- 이유: Docker 명령어 호환, 보안 강화

## 성능 비교

| 솔루션            | 시작 시간 | 메모리 사용 | 격리 수준 | 사용 난이도 |
| ----------------- | --------- | ----------- | --------- | ----------- |
| NixOS Test (QEMU) | ~10초     | 중간        | 높음      | 쉬움        |
| Firecracker       | 125ms     | 5MB         | 매우 높음 | 중간        |
| nixos-shell       | ~5초      | 중간        | 높음      | 매우 쉬움   |
| NixOS Containers  | <1초      | 낮음        | 중간      | 쉬움        |
| Podman            | ~2초      | 낮음        | 중간      | 쉬움        |

## Best Practices

1. **테스트 자동화**: Flake의 `checks` 속성 활용
2. **리소스 최적화**: 필요한 최소 메모리/CPU 설정
3. **재현성**: Flake lock 파일로 버전 고정
4. **디버깅**: Interactive 모드 활용
5. **macOS 사용자**: Linux builder 설정으로 크로스 플랫폼 테스트 가능

## macOS에서 실행하기

### 필수 설정

1. **nix-darwin 설정 업데이트**:

```nix
# hosts/darwin/default.nix
{
  nix.linux-builder.enable = true;
  nix.settings.system-features = [ "nixos-test" "apple-virt" ];
}
```

2. **설정 적용**:

```bash
darwin-rebuild switch --flake .#
```

3. **테스트 실행** (Linux 시스템과 동일):

```bash
nix flake check
# 또는
make test-vm
```

### 장점

- **개발 머신에서 직접 테스트**: 별도 Linux 머신 없이 macOS에서 NixOS 설정 검증
- **CI/CD 일관성**: 로컬 개발 환경과 CI 환경 동일한 테스트 실행
- **크로스 플랫폼 검증**: darwin과 linux 설정을 동시에 검증 가능

## 참고 자료

### 공식 문서

- [NixOS VM Tests Wiki](https://wiki.nixos.org/wiki/NixOS_VM_tests)
- [nix.dev VM Documentation](https://nix.dev/tutorials/nixos/integration-testing-using-virtual-machines.html)
- [NixOS Virtual Machines on macOS](https://wiki.nixos.org/wiki/NixOS_virtual_machines_on_macOS)

### macOS 지원

- [Running NixOS Integration Tests on macOS (nixcademy)](https://nixcademy.com/posts/running-nixos-integration-tests-on-macos/)
- [macOS Support Announcement (NixOS Discourse)](https://discourse.nixos.org/t/macos-support-for-running-nixos-tests/40801)
- [Running a NixOS VM on macOS (Tweag)](https://www.tweag.io/blog/2023-02-09-nixos-vm-on-macos/)

### 기타 도구

- [microVM.nix GitHub](https://github.com/astro/microvm.nix)
- [nixos-shell GitHub](https://github.com/Mic92/nixos-shell)
- [Blake Smith's Flake Testing Guide (2024)](https://blakesmith.me/2024/03/02/running-nixos-tests-with-flakes.html)
