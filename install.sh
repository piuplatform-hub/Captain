#!/usr/bin/env bash
# =====================================================================
# Script tự động thiết lập Dotfiles trên Linux / WSL / macOS
# =====================================================================
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Đang thiết lập dotfiles trên môi trường Unix/Linux/WSL ==="

# 1. Cấu hình Neovim
NVIM_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
if [ -d "$NVIM_CONFIG_DIR" ]; then
    echo "Sao lưu nvim cũ sang ${NVIM_CONFIG_DIR}.backup..."
    mv "$NVIM_CONFIG_DIR" "${NVIM_CONFIG_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
fi
mkdir -p "$(dirname "$NVIM_CONFIG_DIR")"
cp -r "$DOTFILES_DIR/nvim" "$NVIM_CONFIG_DIR"
echo "-> Đã sao chép cấu hình Neovim vào $NVIM_CONFIG_DIR"

# 2. Cấu hình WezTerm
cp "$DOTFILES_DIR/wezterm/.wezterm.lua" "$HOME/.wezterm.lua"
echo "-> Đã sao chép cấu hình WezTerm vào $HOME/.wezterm.lua"

# 3. Cấu hình Tmux
cp "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
echo "-> Đã sao chép cấu hình Tmux vào $HOME/.tmux.conf"

echo "=== Hoàn tất cài đặt dotfiles! ==="
