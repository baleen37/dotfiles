{ config
, pkgs
, lib
, ...
}:

let
  getUser = import ../../lib/user-resolution.nix {
    returnFormat = "string";
  };
  user = getUser;
in

{
  imports = [
    ../../modules/shared
  ];

  # VSCode CLI와 Remote Tunnels 설정
  environment.systemPackages = with pkgs; [
    # VSCode CLI (모든 플랫폼 지원)
    # Note: VSCode CLI는 동적으로 다운로드되므로 직접 설치하지 않음
    curl
    wget

    # 개발 도구들
    git
    vim
    tmux

    # 추가 개발 도구는 shared packages에서 관리
  ];

  # SSH 서버 활성화 (원격 접속용)
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PubkeyAuthentication = true;
      PermitRootLogin = "no";
    };
  };

  # VSCode Tunnel을 위한 사용자 서비스 설정
  systemd.user.services.vscode-tunnel = {
    enable = true;
    description = "VSCode Remote Tunnel";
    wantedBy = [ "default.target" ];
    after = [ "network.target" ];

    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = 10;
      # VSCode CLI를 다운로드하고 tunnel 실행
      ExecStart = "${pkgs.bash}/bin/bash -c 'cd $HOME && curl -Lk \"https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64\" --output vscode_cli.tar.gz && tar -xf vscode_cli.tar.gz && ./code tunnel --accept-server-license-terms'";
    };

    environment = {
      HOME = "/home/${user}";
    };
  };

  system = {
    stateVersion = "23.11"; # NixOS 버전에 맞게 설정
  };

  # 사용자 설정
  users.users.${user} = {
    isNormalUser = true;
    home = "/home/${user}";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      # SSH 키를 여기에 추가하거나 별도 파일에서 import
    ];
  };

  programs.zsh.enable = true;
}
