-- Pull in the wezterm API
local wezterm = require "wezterm"

-- This will hold the configuration.
local config = wezterm.config_builder()

-- Window size
config.initial_rows = 30
config.initial_cols = 110

-- Use wsl
-- config.default_domain = "WSL:Ubuntu"
config.font_size = 18.5

-- Set the color scheme
config.color_scheme = "Gruvbox"

-- Set the transparency of the background
config.window_background_opacity = 0.8

-- No tabs at the top
config.hide_tab_bar_if_only_one_tab = true
config.window_close_confirmation = "NeverPrompt"

-- Turn off ligatures
config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }

-- Remove window border
-- config.window_decorations = "NONE"

-- Set custom font
-- config.font = wezterm.font("JetBrains Mono", {
--   weight = "Thin",
-- })
--
-- config.font = wezterm.font("Times New Roman", { weight = "Regular", stretch = "Normal", style = "Normal" }) -- /System/Library/Fonts/Supplemental/Times New Roman.ttf, CoreText
-- config.font = wezterm.font("Times New Roman", {
-- })
--
config.font = wezterm.font(
  "JetBrains Mono",
  { weight = "Thin", stretch = "Normal", style = "Normal" }
) -- <built-in>, BuiltIn
-- config.font = wezterm.font_with_fallback {
--   wezterm.font('JetBrains Mono', { weight = 'Bold' }),
--   -- "JetBrains Mono NL",
--   -- "Fira Code",
--   -- "Noto Color Emoji",
-- }

-- Set padding around the terminal
config.window_padding = {
  left = 5,
  right = 5,
  top = 5,
  bottom = 5,
}

-- Enable scrollback
config.enable_scroll_bar = true

-- Set the number of scrollback lines
config.scrollback_lines = 5000

-- Set custom cursor style
config.default_cursor_style = "BlinkingBlock"

local wezterm_key = "CTRL|SHIFT"
config.keys = config.keys or {}
-- Tab navigation with ALT+1-9
for i = 1, 9 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = wezterm_key,
    action = wezterm.action { ActivateTab = i - 1 },
  })
end
-- Relative moving with CTRL+SHIFT+h/l or Left/RightArrow
local combos = {
  { key = "LeftArrow", action = -1 },
  { key = "RightArrow", action = 1 },
  { key = "h", action = -1 },
  { key = "l", action = 1 },
}
for _, combo in ipairs(combos) do
  table.insert(config.keys, {
    key = combo.key,
    mods = wezterm_key,
    action = wezterm.action { ActivateTabRelative = combo.action },
  })
end

return config
