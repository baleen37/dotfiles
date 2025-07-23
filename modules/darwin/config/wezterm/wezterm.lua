local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Catppuccin Mocha 테마 사용 (OS 다크모드 자동 연동)
local function scheme_for_appearance(appearance)
  if appearance:find 'Dark' then
    return 'Catppuccin Mocha'
  else
    return 'Catppuccin Latte'
  end
end

config.color_scheme = scheme_for_appearance(wezterm.gui.get_appearance())

-- 폰트 설정 (macOS 모노스페이스 폰트, SF Mono 대신 더 호환성 좋은 폰트 사용)
config.font = wezterm.font_with_fallback({
  'SFMono-Regular',  -- SF Mono의 정확한 PostScript 이름
  'Menlo',
  'Monaco',
  'JetBrains Mono',
  'Consolas',
  'monospace',
})
config.font_size = 14
config.use_fancy_tab_bar = false

-- 터미널 설정
config.scrollback_lines = 10000
config.window_background_opacity = 0.9
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

-- 윈도우 설정
config.window_decorations = 'RESIZE'
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = false

-- 기타 설정
config.audible_bell = 'Disabled'
config.check_for_updates = false
config.automatically_reload_config = true

return config
