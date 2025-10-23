#!/usr/bin/env bash
# Fedora i3 Dracula config dependencies installer

set -e

echo ">>> Updating system..."
sudo dnf update -y

echo ">>> Installing required packages..."
sudo dnf install -y \
  i3 i3status i3lock xss-lock \
  flameshot \
  rofi \
  polybar \
  alacritty \
  dunst \
  xclip xrandr feh \
  nm-applet \
  pavucontrol playerctl \
  git curl \
  neovim \
  fonts-fontawesome \
  network-manager-applet \
  thunar \
  lxappearance

echo ""
echo ">>> Installation complete!"
echo "You now have all apps used in your i3 config installed."

# Optional: Dracula colors for polybar, rofi, etc.
echo ">>> Setting up Dracula theme dependencies..."
sudo dnf install -y papirus-icon-theme

echo ""
echo "🎨 Tip: Set Dracula theme with lxappearance (GTK), and papirus icons."
echo "🎯 If you have a ~/.config/polybar/launch.sh from your dotfiles, make sure it’s executable:"
echo "chmod +x ~/.config/polybar/launch.sh"
echo ""
echo "💡 Run 'i3-msg reload' or re-login to apply everything."
