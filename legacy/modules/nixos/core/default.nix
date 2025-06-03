{ config, pkgs, ... }: {
  # 예시: 시스템 로캘, 시간대, 유저 등 기본 설정
  time.timeZone = "Asia/Seoul";
  i18n.defaultLocale = "en_US.UTF-8";
  # ... 기타 core 설정
}
