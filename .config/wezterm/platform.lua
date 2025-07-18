-- platform.lua
local wezterm = require 'wezterm'
local config = {}

local uname = ""
local ok, result = pcall(wezterm.run_child_process, { "uname", "-a" })
if ok and type(result) == "table" then
  uname = result[1] or ""
end
local target = wezterm.target_triple

local is_windows = target:find("windows")
local is_linux = target:find("linux")
local is_wsl = is_linux and uname:lower():find("microsoft")


print("Platform target: " .. wezterm.target_triple)
print("uname: " .. (uname or "none"))

if is_windows then
  config.default_prog = { "wsl.exe" }
else
  config.default_prog = { "/bin/bash", "-l" }
end

return config
