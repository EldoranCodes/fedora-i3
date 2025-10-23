#!/usr/bin/env bash
# HyDE-style i3 setup for Fedora Minimal
# Author: ChatGPT (for Leonard)
# Target: Low-spec systems / VM / Fedora i3 Minimal Edition

set -e

echo ">>> Updating system..."
sudo dnf update -y

echo ">>> Installing base dependencies..."
sudo dnf install -y \
  alacritty neovim git curl rofi picom feh thunar \
  pavucontrol playerctl NetworkManager-tui brightnessctl \
  i3status i3lock dunst lxappearance xrandr xclip \
  fonts-font-awesome

# --- Create config directories ---
mkdir -p ~/.config/{i3,rofi,alacritty,nvim}
mkdir -p ~/Pictures ~/Documents

# --- i3 config ---
echo ">>> Creating i3 config..."
cat > ~/.config/i3/config <<'EOF'
# ------------------------------
# Fedora i3 Minimal - HyDE Style
# ------------------------------

set $mod Mod4

# Appearance
gaps inner 6
gaps outer 4
font pango:monospace 10

# Background
exec --no-startup-id feh --bg-fill ~/Pictures/wallpaper.jpg

# Compositor
exec --no-startup-id picom --experimental-backends --config /dev/null

# Status bar
bar {
    status_command i3status
    position top
}

# Launch terminal
bindsym $mod+Return exec alacritty

# File manager
bindsym $mod+e exec thunar

# Rofi launcher
bindsym $mod+d exec rofi -show drun

# Reload / Restart / Exit
bindsym $mod+Shift+c reload
bindsym $mod+Shift+r restart
bindsym $mod+Shift+e exec "i3-msg exit"

# Volume and brightness
bindsym XF86AudioRaiseVolume exec "pactl set-sink-volume @DEFAULT_SINK@ +5%"
bindsym XF86AudioLowerVolume exec "pactl set-sink-volume @DEFAULT_SINK@ -5%"
bindsym XF86AudioMute exec "pactl set-sink-mute @DEFAULT_SINK@ toggle"
bindsym XF86MonBrightnessUp exec "brightnessctl set +10%"
bindsym XF86MonBrightnessDown exec "brightnessctl set 10%-"

# ------------------------------
# SCRATCHPADS
# ------------------------------

# Terminal scratchpad
for_window [title="term_scratch"] move to scratchpad
bindsym $mod+t exec --no-startup-id alacritty --title term_scratch
bindsym $mod+Shift+t [title="term_scratch"] scratchpad show

# Notes scratchpad
for_window [title="notes_scratch"] move to scratchpad
bindsym $mod+n exec --no-startup-id alacritty --title notes_scratch -e nvim ~/Documents/scratch.md
bindsym $mod+Shift+n [title="notes_scratch"] scratchpad show

# System monitor scratchpad
for_window [title="htop_scratch"] move to scratchpad
bindsym $mod+m exec --no-startup-id alacritty --title htop_scratch -e htop
bindsym $mod+Shift+m [title="htop_scratch"] scratchpad show

# ------------------------------
# Theme toggle (dark/light)
# ------------------------------
bindsym $mod+Shift+y exec ~/.config/i3/theme-toggle.sh

EOF

# --- Theme toggle script ---
echo ">>> Creating theme toggle script..."
cat > ~/.config/i3/theme-toggle.sh <<'EOF'
#!/usr/bin/env bash
# Simple theme toggle between light and dark wallpaper & picom style

WALL_DARK=~/Pictures/wallpaper-dark.jpg
WALL_LIGHT=~/Pictures/wallpaper-light.jpg
STATE=~/.config/i3/.theme_state

if [[ ! -f "$STATE" ]]; then
  echo "dark" > "$STATE"
fi

MODE=$(cat "$STATE")

if [[ "$MODE" == "dark" ]]; then
  feh --bg-fill "$WALL_LIGHT"
  echo "light" > "$STATE"
else
  feh --bg-fill "$WALL_DARK"
  echo "dark" > "$STATE"
fi

notify-send "Theme toggled to $(cat $STATE)"
EOF

chmod +x ~/.config/i3/theme-toggle.sh

# --- Rofi theme ---
echo ">>> Setting up rofi config..."
cat > ~/.config/rofi/config.rasi <<'EOF'
configuration {
  modi: "drun,run,window";
  theme: "gruvbox-dark";
}
EOF

# --- Final info ---
echo ""
echo "🎉 Done! Log out and choose i3 session on login."
echo "💡 Keybinds:"
echo "  • $mod+Enter = Alacritty terminal"
echo "  • $mod+d = Rofi launcher"
echo "  • $mod+t / $mod+Shift+t = Terminal scratchpad"
echo "  • $mod+n / $mod+Shift+n = Notes scratchpad"
echo "  • $mod+m / $mod+Shift+m = System monitor"
echo "  • $mod+Shift+y = Toggle theme"
echo ""
echo "🧠 Tip: Add wallpapers named 'wallpaper-dark.jpg' and 'wallpaper-light.jpg' in ~/Pictures"
