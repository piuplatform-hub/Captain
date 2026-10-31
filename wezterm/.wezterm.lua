local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

-- =====================================================================
-- 1. KÍCH THƯỚC CỬA SỔ CHUẨN BẰNG CMD: Ngang 120 x Cao 24 (Cỡ chữ 10)
-- =====================================================================
config.initial_cols = 120
config.initial_rows = 24

-- =====================================================================
-- 2. SHELL MẶC ĐỊNH
-- =====================================================================
config.default_prog = { 'powershell.exe' }

-- =====================================================================
-- 3. GIAO DIỆN PHONG CÁCH KUN CHEN (L8 PRINCIPAL ENGINEER)
-- =====================================================================
config.color_scheme = 'rose-pine-moon'
config.win32_system_backdrop = 'Acrylic'
config.window_background_opacity = 0.85
config.max_fps = 120
config.font_size = 10.0
config.font = wezterm.font('JetBrains Mono')

-- Làm tối ô không hoạt động để tập trung
config.inactive_pane_hsb = {
  saturation = 0.7,
  brightness = 0.6,
}

-- =====================================================================
-- 4. TỐI ƯU CHO AI (OPENAI CODEX / AGENTS)
-- =====================================================================
config.scrollback_lines = 10000
config.hyperlink_rules = wezterm.default_hyperlink_rules()

-- =====================================================================
-- 5. BẢNG CHỌN MÀU NHANH
-- =====================================================================
local function select_color_scheme(window, pane)
  local schemes = wezterm.color.get_builtin_schemes()
  local choices = {}
  for name, _ in pairs(schemes) do
    table.insert(choices, { label = name })
  end
  table.sort(choices, function(a, b) return a.label < b.label end)

  window:perform_action(
    act.InputSelector {
      title = 'Chon Bang Mau (Color Scheme)',
      choices = choices,
      fuzzy = true,
      action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
        if label then
          inner_window:set_config_overrides({ color_scheme = label })
        end
      end),
    },
    pane
  )
end

-- =====================================================================
-- 6. BỘ PHÍM TẮT ĐA NHIỆM (CHUẨN CHỮ THƯỜNG THEO NGUYÊN BẢN)
-- =====================================================================
config.keys = {
  -- [Alt + d]: Chia đôi màn hình sang Trái / Phải
  { mods = 'ALT', key = 'd', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },

  -- [Alt + s]: Chia đôi màn hình sang Trên / Dưới
  { mods = 'ALT', key = 's', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },

  -- [Alt + w]: Đóng ô đang chọn
  { mods = 'ALT', key = 'w', action = act.CloseCurrentPane { confirm = false } },

  -- [Alt + z]: Phóng to / Thu nhỏ ô đang chọn (Zoom)
  { mods = 'ALT', key = 'z', action = act.TogglePaneZoomState },

  -- [Alt + Mũi tên]: Chuyển qua lại giữa các ô
  { mods = 'ALT', key = 'LeftArrow',  action = act.ActivatePaneDirection 'Left' },
  { mods = 'ALT', key = 'RightArrow', action = act.ActivatePaneDirection 'Right' },
  { mods = 'ALT', key = 'UpArrow',    action = act.ActivatePaneDirection 'Up' },
  { mods = 'ALT', key = 'DownArrow',  action = act.ActivatePaneDirection 'Down' },

  -- [Alt + h, j, k, l]: Chuyển ô theo chuẩn phím Vim (không cần rời tay khỏi hàng phím)
  { mods = 'ALT', key = 'h', action = act.ActivatePaneDirection 'Left' },
  { mods = 'ALT', key = 'l', action = act.ActivatePaneDirection 'Right' },
  { mods = 'ALT', key = 'k', action = act.ActivatePaneDirection 'Up' },
  { mods = 'ALT', key = 'j', action = act.ActivatePaneDirection 'Down' },

  -- [Alt + c]: Bảng chọn màu nhanh
  { mods = 'ALT', key = 'c', action = wezterm.action_callback(select_color_scheme) },

  -- [Ctrl + Shift + P]: Bảng lệnh Command Palette
  { mods = 'CTRL|SHIFT', key = 'P', action = act.ActivateCommandPalette },
}

return config
