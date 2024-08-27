-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- Window size
config.initial_rows = 30
config.initial_cols = 110

-- Use wsl
config.default_domain = "WSL:Ubuntu"
config.font_size = 12.5

-- Set the color scheme
config.color_scheme = "Gruvbox Dark"

-- Set the transparency of the background
config.window_background_opacity = 0.825

-- No tabs at the top
config.hide_tab_bar_if_only_one_tab = true

config.window_close_confirmation = "NeverPrompt"

-- Turn off ligatures
config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }

-- Remove window border
-- config.window_decorations = "NONE"

-- Set custom font
config.font = wezterm.font_with_fallback({
    "JetBrains Mono",
    "Fira Code",
    "Noto Color Emoji",
})

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

return config
