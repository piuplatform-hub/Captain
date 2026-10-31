<#
.SYNOPSIS
    Script gỡ cài đặt môi trường: WezTerm, Neovim (LazyVim), Tmux/WSL và công cụ bổ trợ.
.DESCRIPTION
    Hỗ trợ dọn dẹp cấu hình, gỡ bỏ phần mềm qua Winget và phục hồi bản sao lưu cũ.
.PARAMETER ConfigsOnly
    Chỉ xóa/khôi phục file cấu hình, giữ nguyên các phần mềm đã cài.
.PARAMETER PurgeAll
    Gỡ bỏ toàn bộ phần mềm và xóa sạch cấu hình.
.PARAMETER WithAI
    Gỡ bỏ kèm cả các công cụ AI (Codex, CloudCode, OpenCode, Antigravity).
#>

param(
    [switch]$ConfigsOnly,
    [switch]$PurgeAll,
    [switch]$WithAI
)

$ErrorActionPreference = "Continue"

Write-Host "==========================================================" -ForegroundColor Red
Write-Host " TRÌNH GỠ CÀI ĐẶT MÔI TRƯỜNG LẬP TRÌNH (UNINSTALL)" -ForegroundColor Yellow
Write-Host " (WezTerm + Neovim LazyVim + Tmux + AI Tools)" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Red

$mode = 0
if ($ConfigsOnly) {
    $mode = 1
} elseif ($PurgeAll) {
    $mode = if ($WithAI) { 3 } else { 2 }
} else {
    Write-Host "`nChọn chế độ gỡ cài đặt bạn mong muốn:" -ForegroundColor Cyan
    Write-Host " [1] Chỉ dọn dẹp FILE CẤU HÌNH (WezTerm, Neovim) - Giữ lại phần mềm đã cài." -ForegroundColor Green
    Write-Host " [2] Gỡ sạch CẤU HÌNH + PHẦN MỀM CỐT LÕI (WezTerm, Neovim, Ripgrep, Fd)." -ForegroundColor Yellow
    Write-Host " [3] Gỡ TOÀN BỘ (Cốt lõi + Cả các công cụ AI: Codex, CloudCode, OpenCode...)." -ForegroundColor Red
    Write-Host " [0] Hủy bỏ (Thoát)." -ForegroundColor DarkGray
    
    $choice = Read-Host "`nNhập lựa chọn của bạn (0/1/2/3)"
    switch ($choice) {
        "1" { $mode = 1 }
        "2" { $mode = 2 }
        "3" { $mode = 3 }
        default {
            Write-Host "Đã hủy bỏ thao tác gỡ cài đặt." -ForegroundColor Green
            exit 0
        }
    }
}

# ---------------------------------------------------------------------
# 1. DỌN DẸP FILE CẤU HÌNH (CONFIGS)
# ---------------------------------------------------------------------
Write-Host "`n[1/3] Đang dọn dẹp file cấu hình..." -ForegroundColor Yellow

# 1.1. Xóa cấu hình WezTerm
$weztermConfig = Join-Path $HOME ".wezterm.lua"
if (Test-Path $weztermConfig) {
    Remove-Item -Path $weztermConfig -Force
    Write-Host " -> Đã xóa file cấu hình: $weztermConfig" -ForegroundColor Green
} else {
    Write-Host " -> Không có file cấu hình WezTerm cần xóa." -ForegroundColor DarkGray
}

# 1.2. Xóa hoặc phục hồi cấu hình Neovim
$nvimConfig = Join-Path $env:LOCALAPPDATA "nvim"
$latestBackup = Get-ChildItem -Path $env:LOCALAPPDATA -Filter "nvim.backup.*" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (Test-Path $nvimConfig) {
    Remove-Item -Path $nvimConfig -Recurse -Force
    Write-Host " -> Đã xóa cấu hình Neovim tại: $nvimConfig" -ForegroundColor Green
}

if ($latestBackup) {
    Write-Host " -> Phát hiện bản sao lưu cũ: $($latestBackup.Name)" -ForegroundColor Cyan
    $restore = Read-Host " -> Bạn có muốn khôi phục lại cấu hình Neovim cũ này không? (Y/N)"
    if ($restore -match "^[yY]") {
        Move-Item -Path $latestBackup.FullName -Destination $nvimConfig -Force
        Write-Host " -> Đã khôi phục thành công cấu hình cũ!" -ForegroundColor Green
    }
}

# 1.3. Dọn dẹp cấu hình trong WSL (nếu có)
if (Get-Command wsl.exe -ErrorAction SilentlyContinue) {
    try {
        wsl bash -c "rm -f ~/.tmux.conf; rm -rf ~/.config/nvim 2>/dev/null"
        Write-Host " -> Đã dọn dẹp cấu hình .tmux.conf và nvim trong WSL!" -ForegroundColor Green
    } catch {
        Write-Host " -> Không thể dọn dẹp trong WSL (có thể bỏ qua)." -ForegroundColor DarkGray
    }
}

# ---------------------------------------------------------------------
# 2. GỠ PHẦN MỀM CỐT LÕI QUA WINGET (NẾU CHỌN CHẾ ĐỘ 2 HOẶC 3)
# ---------------------------------------------------------------------
if ($mode -ge 2) {
    Write-Host "`n[2/3] Đang gỡ cài đặt các phần mềm cốt lõi qua Winget..." -ForegroundColor Yellow

    $coreApps = @(
        @{ Name = "WezTerm"; Id = "wez.wezterm" },
        @{ Name = "Neovim"; Id = "Neovim.Neovim" },
        @{ Name = "Ripgrep"; Id = "BurntSushi.ripgrep.MSVC" },
        @{ Name = "Fd"; Id = "sharkdp.fd" }
    )

    foreach ($app in $coreApps) {
        Write-Host "Đang gỡ $($app.Name)... " -NoNewline
        winget uninstall --id $app.Id --source winget --silent 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[ĐÃ GỠ]" -ForegroundColor Green
        } else {
            Write-Host "[BỎ QUA / CHƯA CÀI]" -ForegroundColor DarkGray
        }
    }
} else {
    Write-Host "`n[2/3] Bỏ qua bước gỡ phần mềm (chỉ dọn dẹp cấu hình)." -ForegroundColor DarkGray
}

# ---------------------------------------------------------------------
# 3. GỠ CÁC CÔNG CỤ AI (NẾU CHỌN CHẾ ĐỘ 3)
# ---------------------------------------------------------------------
if ($mode -eq 3) {
    Write-Host "`n[3/3] Đang gỡ bỏ các công cụ AI..." -ForegroundColor Yellow

    # 3.1. Gỡ OpenAI Codex
    Write-Host "Đang gỡ OpenAI Codex... " -NoNewline
    winget uninstall --id OpenAI.Codex --source winget --silent 2>$null
    npm uninstall -g @openai/codex 2>$null
    Write-Host "[HOÀN TẤT]" -ForegroundColor Green

    # 3.2. Gỡ Google Cloud SDK / Cloud Code
    Write-Host "Đang gỡ Google Cloud SDK... " -NoNewline
    winget uninstall --id Google.CloudSDK --source winget --silent 2>$null
    Write-Host "[HOÀN TẤT]" -ForegroundColor Green

    # 3.3. Gỡ OpenCode
    Write-Host "Đang gỡ OpenCode... " -NoNewline
    pip uninstall -y opencode-ai 2>$null
    npm uninstall -g opencode-ai 2>$null
    Write-Host "[HOÀN TẤT]" -ForegroundColor Green

    # 3.4. Gỡ Antigravity
    $agyDir = Join-Path $env:LOCALAPPDATA "agy"
    if (Test-Path $agyDir) {
        Remove-Item -Path $agyDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host " -> Đã xóa thư mục Antigravity CLI tại: $agyDir" -ForegroundColor Green
    }
} else {
    Write-Host "`n[3/3] Bỏ qua gỡ công cụ AI." -ForegroundColor DarkGray
}

Write-Host "`n==========================================================" -ForegroundColor Red
Write-Host " ĐÃ HOÀN TẤT DỌN DẸP / GỠ CÀI ĐẶT!" -ForegroundColor Green
Write-Host " Hệ thống của bạn đã được đưa về trạng thái sạch sẽ." -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Red
