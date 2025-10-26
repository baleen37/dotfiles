# Nix로 관리하는 QEMU VM 설정

이 문서는 Nix를 사용하여 QEMU 가상 머신을 선언적으로 관리하는 방법을 설명합니다.

## 기능

- **선언적 VM 설정**: 메모리, CPU, 디스크, 네트워크 등을 Nix로 관리
- **자동화된 VM 생성**: VM 디스크 자동 생성 및 관리
- **ISO 기반 설치 지원**: 운영체제 설치를 위한 ISO 마운트
- **네트워크 설정**: 유저 모드 및 브릿지 모드 지원
- **리소스 최적화**: 개발 환경을 위한 효율적인 자원 사용

## 설정 방법

### 1. 기본 VM 모듈 활성화

```nix
# users/baleen/home.nix
{
  imports = [
    ./programs/qemu-vm.nix
  ];

  programs.qemu-vm = {
    enable = true;

    vms = {
      # 테스트용 VM
      nixos-test = {
        name = "nixos-test";
        memory = 2048;
        cores = 2;
        diskSize = "20G";
        diskFormat = "qcow2";
        networkMode = "user";
        graphics = false;
        display = "none";
      };
    };
  };
}
```

### 2. VM 설정 옵션

```nix
{
  programs.qemu-vm = {
    enable = true;

    vms = {
      my-vm = {
        name = "my-vm";
        memory = 4096;          # MB 단위
        cores = 4;              # CPU 코어 수
        diskSize = "40G";       # 디스크 크기
        diskFormat = "qcow2";   # qcow2, raw, vmdk
        networkMode = "user";   # user, bridge
        graphics = true;        # 그래픽 표시
        display = "cocoa";      # gtk, cocoa, vnc, none
        enableKvm = false;      # KVM 가속화 (Linux only)

        # ISO 기반 설치
        iso = "/path/to/os.iso";

        # 공유 폴더
        sharedFolder = {
          host = "/Users/baleen/Projects";
          guest = "/host-projects";
        };

        # 브릿지 네트워크 (networkMode = "bridge"일 때)
        bridgeInterface = "br0";
      };
    };

    # 자동 시작할 VM 목록
    autoStart = [ "my-vm" ];
  };
}
```

## 사용법

### VM 관리 명령어

설정된 VM은 각각의 스크립트로 관리됩니다:

```bash
# VM 시작
qemu-vm-my-vm start

# VM 중지
qemu-vm-my-vm stop

# VM 재시작
qemu-vm-my-vm restart

# VM 상태 확인
qemu-vm-my-vm status

# VM 콘솔 연결 (headless 모드)
qemu-vm-my-vm console
```

### VM 관리자 도구

```bash
# 모든 VM 목록 보기
qemu-vm-manager list

# 모든 VM 시작
qemu-vm-manager start-all

# 모든 VM 중지
qemu-vm-manager stop-all

# 모든 VM 상태 보기
qemu-vm-manager status-all
```

### 셸 알리아스

편리한 셸 알리아스도 제공됩니다:

```bash
vm-list          # VM 목록 보기
vm-start         # 모든 VM 시작
vm-stop          # 모든 VM 중지
vm-status        # 모든 VM 상태 보기

# 개별 VM 접근
nixos-test       # qemu-vm-nixos-test
ubuntu-test      # qemu-vm-ubuntu-test
```

## 예제 설정

### 1. 경량 테스트 VM

```nix
lightweight-test = {
  name = "lightweight-test";
  memory = 1024;
  cores = 1;
  diskSize = "8G";
  networkMode = "user";
  graphics = false;
  display = "none";
};
```

### 2. 개발 환경 VM (GUI 포함)

```nix
development-vm = {
  name = "development-vm";
  memory = 4096;
  cores = 4;
  diskSize = "40G";
  networkMode = "user";
  graphics = true;
  display = "cocoa";
  sharedFolder = {
    host = "/Users/baleen/Projects";
    guest = "/host-projects";
  };
};
```

### 3. 우분투 설치 VM

```nix
ubuntu-installer = {
  name = "ubuntu-installer";
  memory = 2048;
  cores = 2;
  diskSize = "25G";
  iso = "/Users/baleen/Downloads/ubuntu-22.04.3-live-server-amd64.iso";
  networkMode = "user";
  graphics = true;
  display = "cocoa";
};
```

## 파일 구조

VM 데이터는 다음 위치에 저장됩니다:

```
~/.local/share/qemu/vms/
├── vm-name/
│   ├── disk.img          # 가상 디스크
│   └── vm.pid            # VM 프로세스 ID
└── .keep                 # 디렉토리 유지 파일
```

## 문제 해결

### VM이 시작되지 않을 때

1. QEMU가 설치되어 있는지 확인:

   ```bash
   which qemu-system-x86_64
   ```

2. VM 디렉토리 권한 확인:

   ```bash
   ls -la ~/.local/share/qemu/vms/
   ```

3. VM 상태 확인:
   ```bash
   qemu-vm-vm-name status
   ```

### 디스크 공간 부족

VM 디스크가 자동으로 생성되지 않거나 공간이 부족할 때:

```bash
# 수동으로 디스크 생성
qemu-img create -f qcow2 ~/.local/share/qemu/vms/vm-name/disk.img 20G

# 디스크 정보 확인
qemu-img info ~/.local/share/qemu/vms/vm-name/disk.img
```

### 네트워크 문제

- `networkMode = "user"`: 호스트와 자동으로 네트워크 공유
- `networkMode = "bridge"`: 브릿지 인터페이스 필요 (관리자 권한)

## 팁

1. **디스크 사용량 최적화**: `qcow2` 포맷 사용 (스냅샷, 압축 지원)
2. **메모리 최적화**: 필요한 만큼만 할당 (호스트 성능 영향 최소화)
3. **자동 시작**: 개발 환경 VM은 `autoStart`에 추가
4. **백업**: 중요한 VM은 `disk.img` 파일 정기적으로 백업

## 지원 운영체제

- NixOS (권장)
- Ubuntu/Debian
- Alpine Linux
- CentOS/RHEL
- Windows (with proper ISO)
- 기타 x86_64 운영체제
