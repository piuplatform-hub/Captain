<#
.SYNOPSIS
    Script tự động thiết lập môi trường lập trình: WezTerm, Neovim (LazyVim), WSL & Tmux trên Windows.
.DESCRIPTION
    Tự động cài đặt qua Winget, phát hiện & cài đặt WSL nếu chưa có, sao chép cấu hình từ thư mục dotfiles.
.PARAMETER InstallWSL
    Tự động cài đặt WSL mà không cần hỏi xác nhận.
.PARAMETER SkipWSL
    Bỏ qua bước kiểm tra và cài đặt WSL.
#>

param(
    [switch]$InstallWSL,
    [switch]$SkipWSL
)

$ErrorActionPreference = "Continue"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " BẮT ĐẦU CÀI ĐẶT & THIẾT LẬP MÔI TRƯỜNG LẬP TRÌNH" -ForegroundColor Green
Write-Host " (WezTerm + Neovim LazyVim + WSL + Tmux)" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan

$DotfilesDir = $PSScriptRoot

# ---------------------------------------------------------------------
# 1. DANH SÁCH PHẦN MỀM CẦN CÀI QUA WINGET TRÊN WINDOWS
# ---------------------------------------------------------------------
$packages = @(
    @{ Name = "Git"; Id = "Git.Git" },
    @{ Name = "WezTerm"; Id = "wez.wezterm" },
    @{ Name = "Neovim"; Id = "Neovim.Neovim" },
    @{ Name = "Ripgrep (Tìm code nhanh cho Neovim)"; Id = "BurntSushi.ripgrep.MSVC" },
    @{ Name = "Fd (Tìm file nhanh cho Neovim)"; Id = "sharkdp.fd" }
)

Write-Host "`n[1/4] Kiểm tra và cài đặt phần mềm qua Winget..." -ForegroundColor Yellow
foreach ($pkg in $packages) {
    Write-Host "Kiểm tra $($pkg.Name)... " -NoNewline
    $check = winget list --id $pkg.Id --exact 2>$null
    if ($LASTEXITCODE -eq 0 -and ($check -match [regex]::Escape($pkg.Id))) {
        Write-Host "[ĐÃ CÀI ĐẶT]" -ForegroundColor Green
    } else {
        Write-Host "[ĐANG CÀI ĐẶT...]" -ForegroundColor Cyan
        winget install --id $pkg.Id --silent --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -eq 0) {
            Write-Host " -> Cài đặt thành công $($pkg.Name)!" -ForegroundColor Green
        } else {
            Write-Host " -> Không thể cài đặt $($pkg.Name) qua winget, bạn có thể kiểm tra lại sau." -ForegroundColor Red
        }
    }
}

# ---------------------------------------------------------------------
# 2. SAO CHÉP CẤU HÌNH WEZTERM
# ---------------------------------------------------------------------
Write-Host "`n[2/4] Thiết lập cấu hình WezTerm..." -ForegroundColor Yellow
$weztermSrc = Join-Path $DotfilesDir "wezterm\.wezterm.lua"
$weztermDest = Join-Path $HOME ".wezterm.lua"

if (Test-Path $weztermSrc) {
    Copy-Item -Path $weztermSrc -Destination $weztermDest -Force
    Write-Host " -> Đã sao chép cấu hình WezTerm vào: $weztermDest" -ForegroundColor Green
} else {
    Write-Host " -> Không tìm thấy file wezterm\.wezterm.lua!" -ForegroundColor Red
}

# ---------------------------------------------------------------------
# 3. SAO CHÉP CẤU HÌNH NEOVIM (LAZYVIM) TRÊN WINDOWS
# ---------------------------------------------------------------------
Write-Host "`n[3/4] Thiết lập cấu hình Neovim (LazyVim) trên Windows..." -ForegroundColor Yellow
$nvimSrc = Join-Path $DotfilesDir "nvim"
$nvimDest = Join-Path $env:LOCALAPPDATA "nvim"

if (Test-Path $nvimSrc) {
    if (Test-Path $nvimDest) {
        $backupDest = "$nvimDest.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Write-Host " -> Đang sao lưu cấu hình nvim cũ sang: $backupDest" -ForegroundColor DarkGray
        Move-Item -Path $nvimDest -Destination $backupDest -Force
    }
    Copy-Item -Path $nvimSrc -Destination $nvimDest -Recurse -Force
    Write-Host " -> Đã sao chép cấu hình Neovim vào: $nvimDest" -ForegroundColor Green
} else {
    Write-Host " -> Không tìm thấy thư mục nvim!" -ForegroundColor Red
}

# ---------------------------------------------------------------------
# 4. TỰ ĐỘNG PHÁT HIỆN VÀ CÀI ĐẶT WSL + TMUX
# ---------------------------------------------------------------------
Write-Host "`n[4/4] Kiểm tra môi trường WSL và Tmux..." -ForegroundColor Yellow

$tmuxSrc = Join-Path $DotfilesDir "tmux\.tmux.conf"
$hasWSL = $false

# Kiểm tra xem máy đã có bản phân phối WSL nào hoạt động chưa
try {
    $wslList = wsl -l -q 2>$null
    if ($LASTEXITCODE -eq 0 -and $wslList -and ($wslList.Trim().Length -gt 0)) {
        $hasWSL = $true
    }
} catch {
    $hasWSL = $false
}

if (-not $hasWSL) {
    Write-Host " -> Máy hiện TẠI CHƯA CÓ WSL (Windows Subsystem for Linux)." -ForegroundColor Yellow
    
    $shouldInstall = $false
    if ($SkipWSL) {
        Write-Host " -> Bỏ qua cài đặt WSL theo tham số -SkipWSL." -ForegroundColor DarkGray
    } elseif ($InstallWSL) {
        $shouldInstall = $true
    } else {
        # Hỏi người dùng nếu đang chạy trên màn hình tương tác
        Write-Host "`n[?] Tmux là công cụ chạy trên nền Linux (WSL). Bạn có muốn tự động cài đặt WSL (Ubuntu) không? (Y/N): " -ForegroundColor Cyan -NoNewline
        $resp = Read-Host
        if ($resp -match "^[yY]") {
            $shouldInstall = $true
        }
    }

    if ($shouldInstall) {
        Write-Host " -> Đang yêu cầu quyền Administrator để cài đặt WSL & Ubuntu..." -ForegroundColor Cyan
        Write-Host "    (Một cửa sổ xác nhận UAC có thể xuất hiện, vui lòng chọn 'Yes')" -ForegroundColor DarkYellow
        
        # Mở PowerShell với quyền Admin để chạy wsl --install
        $wslCmd = "wsl.exe --install -d Ubuntu --no-launch; Write-Host '`nBấm phím bất kỳ để đóng cửa sổ này...' -ForegroundColor Green; [Console]::ReadKey()"
        Start-Process powershell.exe -ArgumentList "-NoProfile -Command `"$wslCmd`"" -Verb RunAs -Wait

        Write-Host "`n[! LƯU Ý QUAN TRỌNG VỀ WSL !]" -ForegroundColor Yellow
        Write-Host "Nếu đây là lần đầu tiên máy cài WSL, Windows sẽ cần bạn KHỞI ĐỘNG LẠI MÁY (Restart)." -ForegroundColor Yellow
        Write-Host "Sau khi khởi động lại, bạn chỉ cần mở lại PowerShell và chạy lại lệnh:" -ForegroundColor Cyan
        Write-Host "    .\install.ps1" -ForegroundColor Cyan
        Write-Host "Script sẽ nhận diện được WSL và tự động cài Tmux tiếp cho bạn!" -ForegroundColor Green
    } else {
        Write-Host " -> Đã bỏ qua cài WSL. Bạn vẫn có thể dùng WezTerm và Neovim bình thường trên Windows!" -ForegroundColor Green
    }
} else {
    Write-Host " -> ĐÃ PHÁT HIỆN WSL ĐANG HOẠT ĐỘNG!" -ForegroundColor Green
    
    # 1. Tự động cài đặt Tmux bên trong WSL Ubuntu
    Write-Host " -> Đang cập nhật và cài đặt Tmux bên trong WSL..." -ForegroundColor Cyan
    try {
        wsl -u root -- bash -c "apt-get update -qq && apt-get install -y -qq tmux"
        Write-Host " -> Cài đặt Tmux trong WSL thành công!" -ForegroundColor Green
    } catch {
        Write-Host " -> Không thể tự động cài tmux qua apt. Bạn có thể mở WSL gõ 'sudo apt install tmux'." -ForegroundColor DarkYellow
    }

    # 2. Sao chép cấu hình .tmux.conf vào WSL
    if (Test-Path $tmuxSrc) {
        Write-Host " -> Đang đồng bộ cấu hình .tmux.conf vào WSL..." -ForegroundColor Cyan
        Get-Content $tmuxSrc -Raw | wsl bash -c "cat > ~/.tmux.conf"
        Write-Host " -> Đã sao chép .tmux.conf vào thư mục home của WSL!" -ForegroundColor Green
    }

    # 3. Đồng bộ cấu hình LazyVim vào WSL để dùng nvim trong WSL giống hệt Windows
    Write-Host " -> Đang đồng bộ cấu hình Neovim (LazyVim) vào WSL..." -ForegroundColor Cyan
    wsl bash -c "mkdir -p ~/.config/nvim"
    # Sao chép nvim config sang WSL
    $wslNvimPath = wsl bash -c "wslpath -u '$nvimSrc'"
    if ($wslNvimPath) {
        wsl bash -c "cp -r $wslNvimPath/* ~/.config/nvim/ 2>/dev/null"
        Write-Host " -> Đã đồng bộ cấu hình Neovim vào ~/.config/nvim trong WSL!" -ForegroundColor Green
    }
}

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host " HOÀN TẤT SETUP! BẠN ĐÃ SẴN SÀNG LÀM VIỆC." -ForegroundColor Green
Write-Host " - Mở WezTerm lên và bắt đầu code." -ForegroundColor Green
Write-Host " - Phím chuyển ô WezTerm: Alt + Mũi tên hoặc Alt + h/j/k/l." -ForegroundColor Green
if ($hasWSL) {
    Write-Host " - Để mở Tmux: gõ 'wsl' rồi gõ 'tmux'." -ForegroundColor Green
}
Write-Host "==========================================================" -ForegroundColor Cyan
