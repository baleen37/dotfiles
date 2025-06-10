local wezterm = require 'wezterm'

local config = wezterm.config_builder()

-- 색상 테마
config.color_scheme = 'Dark+'

-- 폰트 설정
config.font = wezterm.font('JetBrains Mono', { weight = 'Medium' })
config.font_size = 14.0

-- 윈도우 설정
config.window_background_opacity = 0.95
config.window_padding = {
  left = 10,
  right = 10,
  top = 10,
  bottom = 10,
}

-- 탭 설정
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true

-- 스크롤백 히스토리
config.scrollback_lines = 10000

return config