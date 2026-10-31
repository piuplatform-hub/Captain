# 🚀 Dotfiles: WezTerm + Neovim (LazyVim) + WSL & Tmux + AI Coding (Captain)

Bộ cấu hình cá nhân hóa và script tự động cài đặt môi trường lập trình từ A-Z cho máy mới, tích hợp bộ công cụ trợ lý AI (Antigravity, OpenAI Codex, Cloud Code, OpenCode).

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
- **Bộ công cụ AI Coding Assistants (Tùy chọn)**:
  - **Antigravity CLI (`agy`)**: Trợ lý AI phát triển phần mềm trong terminal.
  - **OpenAI Codex CLI (`codex`)**: Agent AI sinh và chỉnh sửa code tự động.
  - **Google Cloud Code**: Bộ công cụ Google Cloud SDK và Gemini Assist.
  - **OpenCode**: CLI thực thi mã nguồn và phân tích tác vụ AI.
- **Công cụ bổ trợ CLI**:
  - `ripgrep` và `fd` để Neovim tìm kiếm file và text cực nhanh.
  - `Node.js LTS` làm nền tảng runtime cho các CLI AI hiện đại.

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

2. **Các tùy chọn chạy nhanh:**
   - **Cài đặt đầy đủ TẤT CẢ (Core + WSL + Toàn bộ AI Tools):**
     ```powershell
     .\install.ps1 -InstallWSL -WithAI
     ```
   - **Chỉ cài môi trường nhẹ (WezTerm + Neovim, bỏ qua AI và WSL):**
     ```powershell
     .\install.ps1 -SkipWSL -SkipAI
     ```
   - **Chế độ tương tác hỏi từng bước (Mặc định):**
     ```powershell
     .\install.ps1
     ```

---

## 🔑 Hướng dẫn đăng nhập các công cụ AI sau khi cài đặt

Sau khi script hoàn tất, bạn chỉ cần chạy lệnh đăng nhập một lần:
- **Antigravity:** Gõ `agy` trong terminal và đăng nhập tài khoản Google AI Pro.
- **OpenAI Codex:** Gõ `codex login` để liên kết tài khoản OpenAI.
- **Google Cloud Code:** Gõ `gcloud auth login` để đăng nhập.

---

## 🐧 Hướng dẫn cài đặt trên Linux / WSL / macOS

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
