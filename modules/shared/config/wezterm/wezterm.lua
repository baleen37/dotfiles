local wezterm = require 'wezterm'
local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- Color scheme
config.color_scheme = 'Catppuccin Mocha'

-- Font configuration
config.font = wezterm.font('JetBrains Mono', { weight = 'Regular' })
config.font_size = 14.0

-- Window configuration
config.window_decorations = 'RESIZE'
config.window_padding = {
  left = 10,
  right = 10,
  top = 10,
  bottom = 10,
}

-- Tab bar (disabled)
config.enable_tab_bar = false

-- Performance
config.enable_wayland = false

-- Key bindings
config.keys = {
  -- Tab navigation
  {
    key = '{',
    mods = 'ALT|SHIFT',
    action = wezterm.action.MoveTabRelative(-1),
  },
  {
    key = '}',
    mods = 'ALT|SHIFT',
    action = wezterm.action.MoveTabRelative(1),
  },
}

return config