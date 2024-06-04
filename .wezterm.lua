-- Pull in the wezterm API
local wezterm = require "wezterm"

-- This will hold the configuration.
local config = wezterm.config_builder()

-- Window size
config.initial_rows = 30
config.initial_cols = 110

-- Use wsl
config.default_domain = "WSL:Ubuntu"

-- config.color_scheme = "Gruvbox Dark"

-- Set the transparency of the background
config.window_background_opacity = 0.85

-- No tabs at the top
config.hide_tab_bar_if_only_one_tab = true

config.window_close_confirmation = "NeverPrompt"

-- Turn off ligatures
config.harfbuzz_features = {"calt=0", "clig=0", "liga=0"}

return config
