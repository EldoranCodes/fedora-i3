sudo dnf update -y

sudo dnf install -y \
  i3 i3status i3lock \
  alacritty rofi \
  picom feh \
  neovim git curl \
  thunar \
  pavucontrol playerctl \
  xclip xrandr \
  fonts-fontawesome \
  dunst \
  networkmanager-tui

# If you have NVIDIA or other GPU, you might need additional driver packages.
git clone https://github.com/haaarshsingh/dots.git ~/dots
cd ~/dots
