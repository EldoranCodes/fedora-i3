#!/usr/bin/env bash
set -e

echo ">>> Updating system"
sudo pacman -Syu --noconfirm

echo ">>> Installing essentials"
sudo pacman -S --noconfirm \
  base-devel git curl wget unzip zip p7zip \
  xorg-server xorg-xinit xorg-xrandr xorg-xsetroot \
  i3 lxterminal feh picom rofi polybar \
  dmenu network-manager-applet blueman volumeicon \
  zsh neovim vim openssh git \
  firefox dbeaver \
  openjdk17-src openjdk17-doc openjdk17-jdk maven \
  jetbrains-mono-nerd ttf-dejavu \
  maim xclip scrot flameshot \
  thunar gvfs gvfs-smb \
  ntfs-3g htop neofetch

echo ">>> Setting up user environment"
mkdir -p ~/.config/{i3,polybar,rofi,picom}
mkdir -p ~/Pictures/wallpapers

# Set wallpaper
feh --bg-scale /usr/share/backgrounds/archlinux/archbtw.png || true

echo ">>> Configuring i3"
cat > ~/.config/i3/config <<'EOF'
set $mod Mod4

font pango:JetBrainsMono Nerd Font 10
floating_modifier $mod

exec_always --no-startup-id picom --backend xrender --vsync false
exec --no-startup-id nm-applet
exec --no-startup-id blueman-applet
exec --no-startup-id volumeicon
exec --no-startup-id feh --bg-scale ~/Pictures/wallpapers/*

gaps inner 10
gaps outer 10
new_window pixel 2
new_float normal

bindsym $mod+Return exec lxterminal
bindsym $mod+d exec rofi -show drun
bindsym $mod+Shift+q kill
bindsym $mod+Shift+r restart
bindsym $mod+Shift+e exit
bindsym Print exec flameshot gui

# Move and focus
bindsym $mod+h focus left
bindsym $mod+j focus down
bindsym $mod+k focus up
bindsym $mod+l focus right

bindsym $mod+Shift+h move left
bindsym $mod+Shift+j move down
bindsym $mod+Shift+k move up
bindsym $mod+Shift+l move right

# Scratchpad terminal
for_window [class="Scratchpad"] floating enable, move position center, resize set 80 ppt 60 ppt
bindsym $mod+Shift+minus move scratchpad
bindsym $mod+minus scratchpad show
bindsym $mod+Shift+t exec --no-startup-id lxterminal --class=Scratchpad

bar {
  status_command polybar main
  position top
  tray_output primary
}
EOF

echo ">>> Configuring Polybar"
cat > ~/.config/polybar/config.ini <<'EOF'
[bar/main]
width = 100%
height = 24
background = #1e1e2e
foreground = #cdd6f4
font-0 = JetBrainsMono Nerd Font:style=Regular:pixelsize=12

modules-left = i3
modules-right = pulseaudio memory cpu date

[module/i3]
type = internal/i3
format = <label-state> <label-mode>

[module/memory]
type = internal/memory
interval = 5
format = RAM %percentage_used%%

[module/cpu]
type = internal/cpu
interval = 5
format = CPU %percentage%%

[module/date]
type = internal/date
interval = 10
date = %a %b %d %I:%M %p

[module/pulseaudio]
type = internal/pulseaudio
format-volume = VOL %percentage%%
EOF

echo ">>> Configuring Picom"
cat > ~/.config/picom/picom.conf <<'EOF'
backend = "xrender";
vsync = false;
shadow = true;
corner-radius = 8;
inactive-opacity = 0.9;
active-opacity = 1.0;
blur-method = "none";
EOF

echo ">>> Setting up .xinitrc"
cat > ~/.xinitrc <<'EOF'
#!/bin/sh
exec i3
EOF

echo ">>> Changing shell to zsh"
chsh -s /usr/bin/zsh

echo ">>> Done! Run 'startx' to launch i3"
