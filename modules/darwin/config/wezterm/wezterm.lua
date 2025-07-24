local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- 다크 테마 고정 설정 (더 어두운 테마 사용)
config.color_scheme = 'Tokyo Night'

-- 폰트 설정 (JetBrains Mono 우선, CJK 지원)
config.font = wezterm.font_with_fallback({
  'JetBrains Mono',
  'Apple Color Emoji',
  'Hiragino Sans',
  'Hiragino Kaku Gothic ProN',
  'Noto Sans CJK JP',
  'Noto Sans CJK KR',
  'Noto Sans CJK SC',
  'Noto Sans CJK TC',
  'Menlo',
  'Monaco',
})
config.font_size = 14
config.use_fancy_tab_bar = false

-- 터미널 설정
config.scrollback_lines = 10000
config.window_background_opacity = 1.0  -- 완전 불투명
config.initial_cols = 80
config.initial_rows = 25

-- 키 바인딩 (iTerm2와 동일)
config.keys = {
  -- Ctrl+Shift+Arrow 키 매핑
  { key = 'UpArrow', mods = 'CTRL|SHIFT', action = wezterm.action.SendString '\x1b[1;6A' },
  { key = 'DownArrow', mods = 'CTRL|SHIFT', action = wezterm.action.SendString '\x1b[1;6B' },
  { key = 'LeftArrow', mods = 'CTRL|SHIFT', action = wezterm.action.SendString '\x1b[1;6D' },
  { key = 'RightArrow', mods = 'CTRL|SHIFT', action = wezterm.action.SendString '\x1b[1;6C' },

  -- Home/End 키 매핑
  { key = 'Home', mods = 'CTRL', action = wezterm.action.SendString '\x1b[1;5H' },
  { key = 'End', mods = 'CTRL', action = wezterm.action.SendString '\x1b[1;5F' },
}

-- 마우스 설정
config.mouse_bindings = {
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'NONE',
    action = wezterm.action.CompleteSelection 'ClipboardAndPrimarySelection',
  },
}

-- 윈도우 설정 (둥근 모서리 제거)
config.window_decorations = 'MACOS_FORCE_SQUARE_CORNERS|RESIZE'
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = false

-- 기타 설정
config.audible_bell = 'Disabled'
config.check_for_updates = false
config.automatically_reload_config = true

return config
