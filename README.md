# 🚀 Dotfiles: WezTerm + Neovim (LazyVim) + WSL & Tmux (Captain)

Bộ cấu hình cá nhân hóa và script tự động cài đặt môi trường lập trình từ A-Z cho máy mới.

---

## 📦 Các thành phần bao gồm

- **WezTerm** (`wezterm/.wezterm.lua`):
  - Giao diện đẹp `rose-pine-moon`, độ mờ Acrylic 0.85.
  - Phím chia đôi ô: `Alt + d` (ngang), `Alt + s` (dọc), `Alt + w` (đóng ô), `Alt + z` (zoom).
  - Phím chuyển ô: `Alt + Mũi tên` hoặc chuẩn Vim `Alt + h/j/k/l`.
- **Neovim** (`nvim/`):
  - Cấu hình chuẩn theo LazyVim starter.
  - Hỗ trợ đầy đủ plugins, LSP, Treesitter.
- **Tmux & WSL** (`tmux/.tmux.conf`):
  - Tự động phát hiện nếu máy mới chưa có WSL -> Tự động cài đặt WSL & Ubuntu.
  - Tự động cài đặt Tmux và đồng bộ cả `.tmux.conf` lẫn cấu hình Neovim vào WSL.
  - Bật chuột (`mouse on`), hỗ trợ TrueColor 256 colors, phím chia ô trực quan và phím điều hướng `h, j, k, l`.
- **Công cụ bổ trợ CLI**:
  - `ripgrep` và `fd` để Neovim tìm kiếm file và text cực nhanh.

---

## ⚡ Hướng dẫn cài đặt trên máy mới (Windows)

### Cách chạy:

1. Mở **PowerShell** trên máy mới và chạy:
   ```powershell
   git clone https://github.com/piuplatform-hub/Captain.git $HOME/dotfiles
   cd $HOME/dotfiles
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   .\install.ps1
   ```

2. **Cơ chế tự động của script:**
   - Cài đặt Git, WezTerm, Neovim, ripgrep, fd qua Winget.
   - Copy file `.wezterm.lua` và cấu hình Neovim trên Windows.
   - **Tự động kiểm tra WSL**:
     - Nếu máy **chưa có WSL**: Script sẽ hỏi bạn có muốn cài WSL (Ubuntu) không. Nếu chọn `Y`, script tự động gọi quyền Admin (UAC) để chạy `wsl --install -d Ubuntu`.
     - *(Lưu ý: Lần đầu cài WSL, Windows sẽ cần bạn khởi động lại máy để kích hoạt ảo hóa. Sau khi khởi động lại, chỉ cần chạy lại `.\install.ps1` là hoàn tất).*
     - Nếu máy **đã có WSL**: Script tự động cài `tmux` trong Ubuntu, nạp file `.tmux.conf` và đồng bộ cả LazyVim sang WSL.

> [!TIP]
> **Tham số chạy nhanh:**
> - Tự động cài luôn WSL không cần hỏi: `.\install.ps1 -InstallWSL`
> - Bỏ qua WSL (chỉ cài WezTerm + Neovim cho Windows): `.\install.ps1 -SkipWSL`

---

## 🐧 Hướng dẫn cài đặt trên Linux / WSL / macOS

1. Mở Terminal:
   ```bash
   git clone https://github.com/piuplatform-hub/Captain.git ~/dotfiles
   cd ~/dotfiles
   chmod +x install.sh
   ./install.sh
   ```

---

## 📤 Cập nhật thay đổi lên GitHub

Khi có thay đổi cấu hình mới, bạn chỉ cần chạy:

```powershell
cd C:\Users\Hero\dotfiles
git add .
git commit -m "update: sync new changes"
git push origin main
```
