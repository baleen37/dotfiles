{
  config,
  lib,
  pkgs,
  ...
}:
{
  # WezTerm 관련 설정
  home.packages = with pkgs; [
    wezterm
  ];

  # WezTerm 설정 파일 경로
  # home.file.".config/wezterm/wezterm.lua".source = ./wezterm.lua;

  # WezTerm 관련 추가 설정...
  #   home.activation.configureWezTerm = lib.hm.dag.entryAfter ["writeBoundary"] ''
  #   if [ -d "$HOME/.config/wezterm" ]; then
  #     echo "Configuring WezTerm settings..."
  #     # WezTerm 설정 파일 복사
  #     cp -r $HOME/.config/wezterm $HOME/.config/wezterm_backup
  #     echo "WezTerm configuration complete"
  #   else
  #     echo "WezTerm is not installed or not found. Skipping configuration."
  #   fi
  # '';
}
