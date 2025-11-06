#!/usr/bin/env bash
# install.sh
# Debian-focused automated setup for i3 desktop + dev tools on a low-spec laptop
# NOTE: Run as root or with sudo. This script attempts safe fallbacks if packages
# are not found in apt. It will prompt when necessary.

set -euo pipefail

# --- Variables (customize before running) ---
USER_NAME="$(logname 2>/dev/null || echo $SUDO_USER || echo "$USER")"
USER_HOME="/home/${USER_NAME}"
LOCALE="en_US.UTF-8"
JAVA_PACKAGE="openjdk-17-jdk"

# --- Helper functions ---
info(){ echo -e "\e[34m[INFO]\e[0m $*"; }
warn(){ echo -e "\e[33m[WARN]\e[0m $*"; }
err(){ echo -e "\e[31m[ERROR]\e[0m $*"; }
run_as_user(){ su - "$USER_NAME" -c "$*"; }

# Check running as root or with sudo
if [ "$EUID" -ne 0 ]; then
  err "Please run this script with sudo or as root."; exit 1
fi

info "Updating apt..."
apt update && apt upgrade -y

info "Installing core packages..."
apt install -y --no-install-recommends \
  xorg openbox i3 i3blocks i3status lxterminal picom rofi \
  build-essential curl wget git unzip ca-certificates \
  ${JAVA_PACKAGE} neovim zsh fonts-jetbrains-mono \
  pulseaudio pavucontrol scrot xdotool xss-lock xclip \
  imagemagick # imagemagick used for screenshot tweaks

# Polybar: try apt, otherwise build
if apt show polybar >/dev/null 2>&1; then
  info "Installing polybar from apt..."
  apt install -y polybar
else
  warn "polybar not available via apt. Will attempt to build from source (may take time)."
  apt install -y cmake cmake-data libpulse-dev libx11-dev libxrandr-dev libx11-xcb-dev libxcb-ewmh-dev libxcb-icccm4-dev libxcb-image0-dev libxcb-randr0-dev libxcb-util-dev libxcb-xkb-dev libxcb-xrm-dev libxcb1-dev libxcb-cursor-dev libxcb-keysyms1-dev python3-xcbgen xcb-proto libxcb1-dev pkg-config libasound2-dev libjsoncpp-dev
  git clone --depth=1 https://github.com/polybar/polybar.git /tmp/polybar
  cd /tmp/polybar
  ./build.sh
  cd -
fi

# Install i3-gaps if available - optional (gaps require the patched i3)
if apt show i3-wm >/dev/null 2>&1 && apt show i3-gaps >/dev/null 2>&1; then
  info "Installing i3-gaps via apt..."
  apt install -y i3-gaps
else
  warn "i3-gaps not in apt. We'll use default i3 and configure borderless windows + faux gaps via gaps script."
fi

# JetBrains Mono fonts (apt package installed above); ensure fc-cache
info "Refreshing font cache..."
fc-cache -f -v || true

# Install Docker client (optional, for convenience)
info "Installing docker.io client (optional)"
apt install -y docker.io docker-compose-plugin || warn "docker.io not available via apt"
systemctl enable --now docker || true
usermod -aG docker "$USER_NAME" || true

# zsh: set as default for user
info "Setting zsh as default shell for $USER_NAME"
if command -v zsh >/dev/null 2>&1; then
  chsh -s "$(command -v zsh)" "$USER_NAME" || warn "chsh failed; you may need to change shell manually"
fi

# Create .config structure and copy basic configs
CONFIG_DIR="$USER_HOME/.config"
mkdir -p "$CONFIG_DIR/i3" "$CONFIG_DIR/polybar" "$CONFIG_DIR/rofi" "$CONFIG_DIR/nvim" "$USER_HOME/.config/i3blocks"
chown -R "$USER_NAME:$USER_NAME" "$USER_HOME/.config"

# Write minimal i3 config (gaps-ish, no borders, welcome keybinds)
cat > "$CONFIG_DIR/i3/config" <<'I3CONF'
# Minimal i3 config (commented, tweak as needed)
# Place this file at ~/.config/i3/config

set $mod Mod4
font pango:JetBrains Mono 10

# Gaps-like behavior using i3-gaps features if available
# If you have i3-gaps, set gaps accordingly; else we'll fake with padding in polybar & windows
gaps inner 10
gaps outer 10

# No window borders
for_window [class=".*"] border none

# Startup apps
exec --no-startup-id picom --config ~/.config/picom/picom.conf
exec --no-startup-id xss-lock -- i3lock -n
exec --no-startup-id nm-applet || true
exec --no-startup-id lxterminal

# Workspace navigation
bindsym $mod+Left workspace prev
bindsym $mod+Right workspace next
bindsym $mod+Return exec lxterminal
bindsym $mod+d exec rofi -show drun

# Volume controls (requires pactl)
bindsym XF86AudioRaiseVolume exec pactl set-sink-volume @DEFAULT_SINK@ +5%
bindsym XF86AudioLowerVolume exec pactl set-sink-volume @DEFAULT_SINK@ -5%
bindsym XF86AudioMute exec pactl set-sink-mute @DEFAULT_SINK@ toggle

# Screenshot
bindsym Print exec scrot '%Y-%m-%d_%H-%M-%S_screenshot.png' -e 'mv $f $HOME/Pictures/'

# i3bar/i3status (fallback) - see README for polybar info
bar {
    status_command i3status
}

# Basic window management
bindsym $mod+Shift+q kill
bindsym $mod+Shift+r restart
bindsym $mod+Shift+e exit

# Floating toggle
bindsym $mod+Shift+space floating toggle

# Comments: tweak gaps and borders above. If using i3-gaps, use 'gaps inner/outer' commands.
I3CONF

chown "$USER_NAME:$USER_NAME" "$CONFIG_DIR/i3/config"

# Picom config
mkdir -p "$CONFIG_DIR/picom"
cat > "$CONFIG_DIR/picom/picom.conf" <<'PIC'
# Basic picom config optimized for low-end hardware
backend = "glx";
vsync = true;
blur-method = "none";
shadow = false;
fade = false;

# Reduce overhead
shadow-exclude = [ "class_g = 'i3bar'" ];
PIC
chown -R "$USER_NAME:$USER_NAME" "$CONFIG_DIR/picom"

# i3blocks sample configuration (shows time, cpu, mem, disk)
cat > "$CONFIG_DIR/i3blocks/config" <<'BLOCK'
# Simple blocks config
[time]
command=date '+%Y-%m-%d %H:%M'
interval=30

[cpu]
command=top -bn1 | grep "Cpu(s)" | awk '{print $2+$4 "%"}'
interval=5

[mem]
command=free -h | awk '/^Mem:/ {print $3"/"$2}'
interval=10

[disk]
command=df -h / | awk 'NR==2 {print $3"/"$2}'
interval=300
BLOCK
chown -R "$USER_NAME:$USER_NAME" "$CONFIG_DIR/i3blocks"

# Basic polybar config (if installed)
cat > "$CONFIG_DIR/polybar/config" <<'POLY'
[bar/mybar]
width = 100%
height = 24
modules-left = xworkspaces
modules-center = cpu memory\ nmodules-right = date

[module/xworkspaces]
type = internal/xworkspaces

[module/cpu]
type = internal/cpu

[module/memory]
type = internal/memory

[module/date]
type = internal/date
format = %Y-%m-%d %H:%M
POLY
chown -R "$USER_NAME:$USER_NAME" "$CONFIG_DIR/polybar"

# Rofi theme (Nord-like minimal)
cat > "$CONFIG_DIR/rofi/theme.rasi" <<'ROFI'
/* Nordish simple rofi theme */
configuration {
  font: "JetBrains Mono 10";
  background: #2E3440ff;
  text: #D8DEE9ff;
  selected: #88C0D0ff;
}
ROFI
chown -R "$USER_NAME:$USER_NAME" "$CONFIG_DIR/rofi"

# Minimal Neovim init.vim
mkdir -p "$USER_HOME/.config/nvim"
cat > "$USER_HOME/.config/nvim/init.vim" <<'NVIM'
" Minimal init.vim with plugin manager (vim-plug)
call plug#begin('~/.local/share/nvim/plugged')
Plug 'preservim/nerdtree'
Plug 'tpope/vim-fugitive'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
call plug#end()

syntax on
set number
NVIM
chown -R "$USER_NAME:$USER_NAME" "$USER_HOME/.config/nvim"

# Zshrc basic
cat > "$USER_HOME/.zshrc" <<'ZSH'
# Basic zsh config
export TERM=xterm-256color
export EDITOR=nvim
alias ll='ls -lah'
# Set prompt
PROMPT='%F{cyan}%n@%m%f %F{yellow}%~%f %# '
ZSH
chown "$USER_NAME:$USER_NAME" "$USER_HOME/.zshrc"

# Create Pictures folder for screenshots
mkdir -p "$USER_HOME/Pictures"
chown "$USER_NAME:$USER_NAME" "$USER_HOME/Pictures"

# Enable services: dbus, pulseaudio user session is started on login
systemctl enable --now dbus || true

info "Setup complete. Some packages may require a logout/login to take effect."
info "You should now be able to login into i3 (select i3 session in your display manager or run startx)."
info "User-specific configs are placed in $USER_HOME/.config — edit them to tweak colors, gaps, and modules."

cat <<'POST'

Post-setup tips (manual):
- If polybar was built, you may want to create a launcher script in ~/.config/polybar/launch.sh to start it on i3 startup.
- To apply Nord or Gruvbox color schemes, edit the rofi/theme.rasi and polybar colors.
- To remove window borders and add gaps, use 'for_window [class=".*"] border none' and 'gaps inner/outer' in i3 config.
- If you want i3-gaps and it's not in apt, consider building i3-gaps from source or using a distro that ships it.
- Reboot or logout/login after chsh to set zsh as default.

POST

exit 0

# ------------------
# Additional files included in this repo (in this textdoc):
# - README.md (instructions + tweak guide)
# - i3/config (already written to ~/.config/i3/config)
# - picom/picom.conf
# - polybar/config
# - rofi/theme.rasi
# - nvim/init.vim
# - .zshrc
#
# Edit them as needed.
