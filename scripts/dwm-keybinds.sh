#!/bin/bash
# dwm-keybinds

KEYBINDS="
# ──────────────────────────────────────
#  APPLICATIONS
# ──────────────────────────────────────
Super + x                    Terminal  (st)
Super + r                    App Launcher  (rofi)
Super + b                    Browser   (firefox)
Super + e                    File Manager   (pcmanfm)
Super + p                    Screenshot  (flameshot)
Super + Shift + p             Fullscreen Screenshot 
Super + Shift + w             Random Wallpaper 󰸉
Super + grave                Scratchpad Terminal 
Super + Ctrl + q             Power Menu 󰐥

# ──────────────────────────────────────
#  WINDOW MANAGEMENT
# ──────────────────────────────────────
Super + q                    Kill Window 
Super + Shift + Space        Toggle Floating
Super + f                    Toggle Fullscreen 󰊓
Super + Return               Zoom 
Super + Tab                  Switch Focus 󰓩
Super + j                    Focus Next Window 󰮰
Super + k                    Focus Previous Window 󰮲
Super + Shift + j            Move Window Down Stack 
Super + Shift + k            Move Window Up Stack 
Super + Left                 Focus Left 
Super + Right                Focus Right 
Super + Shift + Left         Move Window Left 
Super + Shift + Right        Move Window Right 
Super + h                    Decrease Master Width
Super + l                    Increase Master Width
Super + i                    Increase Master Count
Super + d                    Decrease Master Count

# ──────────────────────────────────────
#  LAYOUTS
# ──────────────────────────────────────
Super + t                    Tile Layout
Super + m                    Monocle Layout
Super + Space                Toggle Last Layout
Super + Ctrl + ,             Previous Layout
Super + Ctrl + .             Next Layout

# ──────────────────────────────────────
#  GAPS
# ──────────────────────────────────────
Super + Win + u              Increase All Gaps
Super + Win + Shift + u      Decrease All Gaps
Super + Win + 0              Toggle Gaps
Super + Win + Shift + 0      Reset Gaps

# ──────────────────────────────────────
#  TAGS / WORKSPACES
# ──────────────────────────────────────
Super + [1-9]                Switch to Tag 1-9
Super + Shift + [1-9]        Move Window to Tag 1-9
Super + Ctrl + [1-9]         Toggle View Tag 1-9
Super + 0                    View All Tags
Super + Shift + 0            Tag Window to All Tags

# ──────────────────────────────────────
#  MONITORS
# ──────────────────────────────────────
Super + ,                    Focus Previous Monitor
Super + .                    Focus Next Monitor
Super + Shift + ,            Move Window to Prev Monitor
Super + Shift + .            Move Window to Next Monitor

# ──────────────────────────────────────
#  MEDIA KEYS
# ──────────────────────────────────────
XF86AudioRaiseVolume         Volume Up 5% 󰝝
XF86AudioLowerVolume         Volume Down 5% 󰝞
XF86AudioMute                Toggle Mute 󰖁
XF86MonBrightnessUp          Brightness Up 5% 
XF86MonBrightnessDown        Brightness Down 5%

# ──────────────────────────────────────
#  DWM
# ──────────────────────────────────────
Super + Shift + e            Exit dwm 󰩈
"

# display in rofi
echo "$KEYBINDS" | grep -v "^$" | grep -v "^#" | \
rofi -dmenu \
     -i \
     -p "keybinds" \
     -theme-str 'window {width: 700px;}' \
     -theme-str 'listview {lines: 10;}' \
     -no-custom \
     -format 'i'
