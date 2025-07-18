local wezterm = require 'wezterm'

local M = {}

function M.spawn_named_tab()
  return wezterm.action_callback(function(window, _)
    window:perform_action(
      wezterm.action.SpawnTab("CurrentPaneDomain"),
      window:active_pane()
    )

    -- Delay the prompt very slightly to give the new tab time to activate
    wezterm.sleep_ms(50)

    window:perform_action(
      wezterm.action.PromptInputLine {
        description = 'Name this tab',
        action = wezterm.action_callback(function(win, _, line)
          if line then
            win:perform_action(
              wezterm.action.SetTabTitle(line),
              win:active_pane()
            )
          end
        end)
      },
      window:active_pane()
    )
  end)
end

return M
