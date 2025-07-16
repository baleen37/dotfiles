# Shared File Configurations
#
# 모든 플랫폼에서 공통으로 사용되는 파일 설정을 정의합니다.

{ self, ... }:

let
  # Claude config source directory
  claudeConfigDir = "${self}/modules/shared/config/claude";
in
{
  # Claude commands directory symlink to dotfiles
  ".claude/commands" = {
    source = "${claudeConfigDir}/commands";
    recursive = true;
  };
}
