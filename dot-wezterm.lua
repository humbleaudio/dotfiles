local wezterm = require 'wezterm'
local mux = wezterm.mux

-- Build a config table (newer wezterm gives nicer errors with config_builder)
local config = {}
if wezterm.config_builder then
  config = wezterm.config_builder()
end

------------------------------------------------------------
-- gui-startup: set up the two workspaces + layouts
------------------------------------------------------------
wezterm.on('gui-startup', function(cmd)
  -- Preserve args if wezterm was started as: wezterm start -- <something>
  local args = {}
  if cmd and cmd.args then
    args = cmd.args
  end

  --------------------------------------------------------
  -- Workspace: "local"  (two local panes side-by-side)
  --------------------------------------------------------
  do
    local tab, left_pane, window = mux.spawn_window {
      workspace = 'local',
      cwd = wezterm.home_dir,
      args = args, -- usually just your shell
    }

    window:gui_window():maximize()

    -- Right pane: second local shell
    left_pane:split {
      direction = 'Right',
      size = 0.5,          -- 50% / 50%
      cwd = wezterm.home_dir,
    }
  end

  --------------------------------------------------------
  -- Workspace: "apollo" (remote GPU box)
  --  - Left: ssh apollo
  --  - Top-right: ssh apollo + gpustat
  --  - Bottom-right: ssh apollo
  --------------------------------------------------------
  do
    -- Big left pane (ssh apollo)
    local tab, main_pane, window = mux.spawn_window {
      workspace = 'apollo',
      cwd = wezterm.home_dir,
      args = { 'ssh', 'apollo', '-A' },
    }

    -- Top-right pane (ssh apollo)
    local right = main_pane:split {
      direction = 'Right',
      size = 0.33,                -- ~1/3 width on the right
      args = { 'ssh', 'apollo', '-A' },
    }

    -- Bottom-right pane (ssh apollo)
    local bottom_right = right:split {
      direction = 'Bottom',       -- IMPORTANT: "Bottom", not "Down"
      size = 0.5,                 -- half of the right column
      args = { 'ssh', 'apollo', '-A' },
    }

    -- Start GPU stats in top-right
    right:send_text('watch -n0.2 gpustat --color\n')

    -- Optional: cd into project directory on apollo
    main_pane:send_text('cd ~/git/blackwell\n')
    bottom_right:send_text('cd ~/git/blackwell\n')

    -- clear the screen
    main_pane:send_text('clear\n')
    bottom_right:send_text('clear\n')
  end

    --------------------------------------------------------
  -- Workspace: "runpod" (remote GPU box)
  --  - Left: ssh runpod
  --  - Top-right: ssh runpod + gpustat
  --  - Bottom-right: ssh runpod
  --------------------------------------------------------
  do
    -- Big left pane (ssh runpod)
    local tab, main_pane, window = mux.spawn_window {
      workspace = 'runpod-blackwell',
      cwd = wezterm.home_dir,
      args = { 'ssh', 'runpod-blackwell', '-A' },
    }

    -- Top-right pane (ssh runpod)
    local right = main_pane:split {
      direction = 'Right',
      size = 0.33,                -- ~1/3 width on the right
      args = { 'ssh', 'runpod-blackwell', '-A' },
    }

    -- Bottom-right pane (ssh runpod)
    local bottom_right = right:split {
      direction = 'Bottom',       -- IMPORTANT: "Bottom", not "Down"
      size = 0.5,                 -- half of the right column
      args = { 'ssh', 'runpod-blackwell', '-A' },
    }

    -- Start GPU stats in top-right
    right:send_text('watch -n0.2 gpustat --color\n')

    -- Optional: cd into project directory on runpod
    main_pane:send_text('cd  ~/git/blackwell\n')
    bottom_right:send_text('cd ~/git/blackwell\n')

    -- clear the screen
    main_pane:send_text('clear\n')
    bottom_right:send_text('clear\n')
  end

  -- Start focused on the "local" workspace
  mux.set_active_workspace 'local'
end)

------------------------------------------------------------
-- Appearance
------------------------------------------------------------
config.enable_tab_bar = false
config.window_decorations = "RESIZE"   -- or "NONE"
config.font = wezterm.font 'JetBrains Mono'
config.font_size = 14.0
config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }

------------------------------------------------------------
-- Keybindings
------------------------------------------------------------
local act = wezterm.action

config.keys = {
  -- Workspace switching
  { key = '1', mods = 'CMD',        action = act.SwitchToWorkspace { name = 'local' } },
  { key = '2', mods = 'CMD',        action = act.SwitchToWorkspace { name = 'apollo' } },
  { key = '3', mods = 'CMD',        action = act.SwitchToWorkspace { name = 'runpod' } },
  { key = 'N', mods = 'CMD|SHIFT',  action = act.ShowLauncherArgs { flags = 'WORKSPACES' } },

  { key = '1', mods = 'ALT', action = act.ActivatePaneByIndex(0) },
  { key = '2', mods = 'ALT', action = act.ActivatePaneByIndex(1) },
  { key = '3', mods = 'ALT', action = act.ActivatePaneByIndex(2) },
  { key = '4', mods = 'ALT', action = act.ActivatePaneByIndex(3) },
  { key = '5', mods = 'ALT', action = act.ActivatePaneByIndex(4) },
  { key = '6', mods = 'ALT', action = act.ActivatePaneByIndex(5) },
  { key = '7', mods = 'ALT', action = act.ActivatePaneByIndex(6) },
  { key = '8', mods = 'ALT', action = act.ActivatePaneByIndex(7) },
  { key = '9', mods = 'ALT', action = act.ActivatePaneByIndex(8) },
  { key = '0', mods = 'ALT', action = act.ActivatePaneByIndex(9) },

  -- Pane management (similar to iTerm splits)
  { key = 'd', mods = 'CMD',
    action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'd', mods = 'CMD|SHIFT',
    action = act.SplitVertical { domain = 'CurrentPaneDomain' } },

  -- Move between panes with ⌘ + h/j/k/l
  { key = 'h', mods = 'CMD', action = act.ActivatePaneDirection 'Left'  },
  { key = 'l', mods = 'CMD', action = act.ActivatePaneDirection 'Right' },
  { key = 'k', mods = 'CMD', action = act.ActivatePaneDirection 'Up'    },
  { key = 'j', mods = 'CMD', action = act.ActivatePaneDirection 'Down'  },
}

return config

