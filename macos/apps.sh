#!/bin/bash

# =====================
# 🎮 Games
# =====================
games=(
  endless-sky
  openra
  warzone-2100
)

# =====================
# 🛠️ Other Apps
# =====================
tools=(
  1password
  1password-cli
  aldente
  session-manager-plugin
  github
  visual-studio-code
  mysqlworkbench
  pgadmin4
  iterm2
  brave-browser
  wifiman
  slack
  transmit
)

echo "🔧 Installing Homebrew Cask apps..."

# Install games
echo "🎮 Installing games..."
for game in "${games[@]}"; do
  echo "➡️  Installing $game..."
  brew install --cask "$game"
done

# Install other tools
echo "🛠️ Installing other tools..."
for tool in "${tools[@]}"; do
  echo "➡️  Installing $tool..."
  brew install --cask "$tool"
done

echo "✅ All apps installed."
