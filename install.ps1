<#
.SYNOPSIS
    Script tự động thiết lập môi trường lập trình: WezTerm, Neovim (LazyVim), WSL & Tmux, kèm tùy chọn AI Coding Tools.
.DESCRIPTION
    Tự động cài đặt qua Winget, cấu hình WezTerm, Neovim, WSL/Tmux và bộ công cụ AI (Antigravity, Codex, CloudCode, OpenCode).
    Hỗ trợ chạy trực tiếp 1 dòng lệnh từ GitHub (One-liner).
.PARAMETER InstallWSL
    Tự động cài đặt WSL mà không cần hỏi xác nhận.
.PARAMETER SkipWSL
    Bỏ qua bước kiểm tra và cài đặt WSL.
.PARAMETER WithAI
    Tự động cài đặt toàn bộ công cụ AI Coding (Antigravity, Codex, CloudCode, OpenCode).
.PARAMETER SkipAI
    Bỏ qua bước cài đặt công cụ AI.
#>

param(
    [switch]$InstallWSL,
    [switch]$SkipWSL,
    [switch]$WithAI,
    [switch]$SkipAI
)

$ErrorActionPreference = "Continue"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " BẮT ĐẦU CÀI ĐẶT & THIẾT LẬP MÔI TRƯỜNG LẬP TRÌNH" -ForegroundColor Green
Write-Host " (WezTerm + Neovim LazyVim + WSL + Tmux + AI Tools)" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan

# ---------------------------------------------------------------------
# TỰ ĐỘNG PHÁT HIỆN KHI CHẠY TRỰC TIẾP TỪ GITHUB (ONE-LINER)
# ---------------------------------------------------------------------
if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "wezterm\.wezterm.lua"))) {
    $DotfilesDir = $PSScriptRoot
} else {
    $DotfilesDir = Join-Path $HOME "dotfiles"
    if (-not (Test-Path (Join-Path $DotfilesDir "wezterm\.wezterm.lua"))) {
        Write-Host "`n[Phát hiện chạy trực tiếp từ GitHub]" -ForegroundColor Cyan
        Write-Host "Đang chuẩn bị thư mục dotfiles tại: $DotfilesDir..." -ForegroundColor Yellow

        # 1. Đảm bảo có Git
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Write-Host "Máy chưa có Git. Đang cài Git tự động qua Winget..." -ForegroundColor Cyan
            winget install --id Git.Git --source winget --silent --accept-package-agreements --accept-source-agreements
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        }

        # 2. Clone hoặc tải ZIP từ GitHub
        Write-Host "Đang tải repo Captain về máy của bạn..." -ForegroundColor Cyan
        try {
            git clone https://github.com/piuplatform-hub/Captain.git $DotfilesDir
        } catch {
            Write-Host "Clone qua Git không thành công, chuyển sang tải ZIP trực tiếp..." -ForegroundColor Yellow
            $zipPath = "$HOME\captain.zip"
            Invoke-WebRequest -Uri "https://github.com/piuplatform-hub/Captain/archive/refs/heads/main.zip" -OutFile $zipPath -UseBasicParsing
            Expand-Archive -Path $zipPath -DestinationPath "$HOME\captain_temp" -Force
            if (Test-Path $DotfilesDir) { Remove-Item -Path $DotfilesDir -Recurse -Force -ErrorAction SilentlyContinue }
            Move-Item -Path "$HOME\captain_temp\Captain-main" -Destination $DotfilesDir -Force
            Remove-Item -Path $zipPath, "$HOME\captain_temp" -Recurse -Force -ErrorAction SilentlyContinue
        }
    } else {
        Write-Host "`nĐã tìm thấy repo tại $DotfilesDir, đang đồng bộ phiên bản mới nhất..." -ForegroundColor Cyan
        git -C $DotfilesDir pull origin main 2>$null
    }
}

# ---------------------------------------------------------------------
# 1. CÔNG CỤ CỐT LÕI (CORE TOOLS) TRÊN WINDOWS QUA WINGET
# ---------------------------------------------------------------------
$packages = @(
    @{ Name = "Git"; Id = "Git.Git" },
    @{ Name = "WezTerm"; Id = "wez.wezterm" },
    @{ Name = "Neovim"; Id = "Neovim.Neovim" },
    @{ Name = "Ripgrep (Tìm code nhanh cho Neovim)"; Id = "BurntSushi.ripgrep.MSVC" },
    @{ Name = "Fd (Tìm file nhanh cho Neovim)"; Id = "sharkdp.fd" }
)

Write-Host "`n[1/5] Kiểm tra và cài đặt công cụ cốt lõi qua Winget..." -ForegroundColor Yellow
foreach ($pkg in $packages) {
    Write-Host "Kiểm tra $($pkg.Name)... " -NoNewline
    $check = winget list --id $pkg.Id --source winget --exact 2>$null
    if ($LASTEXITCODE -eq 0 -and ($check -match [regex]::Escape($pkg.Id))) {
        Write-Host "[ĐÃ CÀI ĐẶT]" -ForegroundColor Green
    } else {
        Write-Host "[ĐANG CÀI ĐẶT...]" -ForegroundColor Cyan
        winget install --id $pkg.Id --source winget --silent --accept-package-agreements --accept-source-agreements
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
Write-Host "`n[2/5] Thiết lập cấu hình WezTerm..." -ForegroundColor Yellow
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
Write-Host "`n[3/5] Thiết lập cấu hình Neovim (LazyVim) trên Windows..." -ForegroundColor Yellow
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
Write-Host "`n[4/5] Kiểm tra môi trường WSL và Tmux..." -ForegroundColor Yellow

$tmuxSrc = Join-Path $DotfilesDir "tmux\.tmux.conf"
$hasWSL = $false

try {
    $wslList = wsl -l -q 2>$null
    if ($LASTEXITCODE -eq 0 -and $wslList -and ($wslList.Trim().Length -gt 0)) {
        $hasWSL = $true
    }
} catch {
    $hasWSL = $false
}

if (-not $hasWSL) {
    Write-Host " -> Máy hiện tại CHƯA CÓ WSL (Windows Subsystem for Linux)." -ForegroundColor Yellow
    
    $shouldInstallWSL = $false
    if ($SkipWSL) {
        Write-Host " -> Bỏ qua cài đặt WSL theo tham số -SkipWSL." -ForegroundColor DarkGray
    } elseif ($InstallWSL) {
        $shouldInstallWSL = $true
    } else {
        Write-Host "`n[?] Tmux chạy trên Linux (WSL). Bạn có muốn tự động cài đặt WSL (Ubuntu) không? (Y/N): " -ForegroundColor Cyan -NoNewline
        $resp = Read-Host
        if ($resp -match "^[yY]") {
            $shouldInstallWSL = $true
        }
    }

    if ($shouldInstallWSL) {
        Write-Host " -> Đang yêu cầu quyền Administrator để cài đặt WSL & Ubuntu..." -ForegroundColor Cyan
        $wslCmd = "wsl.exe --install -d Ubuntu --no-launch; Write-Host '`nBấm phím bất kỳ để đóng cửa sổ này...' -ForegroundColor Green; [Console]::ReadKey()"
        Start-Process powershell.exe -ArgumentList "-NoProfile -Command `"$wslCmd`"" -Verb RunAs -Wait

        Write-Host "`n[! LƯU Ý QUAN TRỌNG VỀ WSL !]" -ForegroundColor Yellow
        Write-Host "Lần đầu cài WSL, Windows sẽ cần bạn KHỞI ĐỘNG LẠI MÁY (Restart)." -ForegroundColor Yellow
        Write-Host "Sau khi khởi động lại, chỉ cần chạy lại lệnh cài đặt để hoàn tất Tmux." -ForegroundColor Cyan
    } else {
        Write-Host " -> Bỏ qua WSL. WezTerm và Neovim vẫn hoạt động bình thường trên Windows!" -ForegroundColor Green
    }
} else {
    Write-Host " -> ĐÃ PHÁT HIỆN WSL ĐANG HOẠT ĐỘNG!" -ForegroundColor Green
    
    Write-Host " -> Đang cài đặt Tmux trong WSL..." -ForegroundColor Cyan
    try {
        wsl -u root -- bash -c "apt-get update -qq && apt-get install -y -qq tmux"
        Write-Host " -> Cài đặt Tmux trong WSL thành công!" -ForegroundColor Green
    } catch {
        Write-Host " -> Không thể tự động cài tmux qua apt." -ForegroundColor DarkYellow
    }

    if (Test-Path $tmuxSrc) {
        Write-Host " -> Đang đồng bộ .tmux.conf vào WSL..." -ForegroundColor Cyan
        Get-Content $tmuxSrc -Raw | wsl bash -c "cat > ~/.tmux.conf"
        Write-Host " -> Đã sao chép .tmux.conf vào WSL!" -ForegroundColor Green
    }

    Write-Host " -> Đang đồng bộ cấu hình Neovim vào WSL..." -ForegroundColor Cyan
    wsl bash -c "mkdir -p ~/.config/nvim"
    $wslNvimPath = wsl bash -c "wslpath -u '$nvimSrc'"
    if ($wslNvimPath) {
        wsl bash -c "cp -r $wslNvimPath/* ~/.config/nvim/ 2>/dev/null"
        Write-Host " -> Đã đồng bộ cấu hình Neovim vào ~/.config/nvim trong WSL!" -ForegroundColor Green
    }
}

# ---------------------------------------------------------------------
# 5. TÙY CHỌN: BỘ CÔNG CỤ AI CODING ASSISTANTS
# (Antigravity, OpenAI Codex, Cloud Code, OpenCode)
# ---------------------------------------------------------------------
Write-Host "`n[5/5] Kiểm tra bộ công cụ AI Coding (Antigravity, Codex, CloudCode, OpenCode)..." -ForegroundColor Yellow

$shouldInstallAI = $false
if ($SkipAI) {
    Write-Host " -> Bỏ qua cài đặt công cụ AI theo tham số -SkipAI." -ForegroundColor DarkGray
} elseif ($WithAI) {
    $shouldInstallAI = $true
} else {
    Write-Host "`n[?] Bạn có muốn cài đặt thêm bộ công cụ AI Coding (Antigravity, Codex, CloudCode, OpenCode) không? (Y/N): " -ForegroundColor Cyan -NoNewline
    $respAI = Read-Host
    if ($respAI -match "^[yY]") {
        $shouldInstallAI = $true
    }
}

if ($shouldInstallAI) {
    Write-Host "`n--- BẮT ĐẦU CÀI ĐẶT BỘ CÔNG CỤ AI ---" -ForegroundColor Cyan

    # 5.1. Runtime cần thiết: Node.js
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Write-Host " -> Đang cài đặt Node.js LTS (nền tảng cho nhiều CLI AI)..." -ForegroundColor Cyan
        winget install --id OpenJS.NodeJS.LTS --source winget --silent --accept-package-agreements --accept-source-agreements
    }

    # 5.2. Antigravity CLI (agy)
    if (Get-Command agy.exe -ErrorAction SilentlyContinue) {
        Write-Host " -> Antigravity CLI (agy): [ĐÃ CÀI ĐẶT]" -ForegroundColor Green
    } else {
        Write-Host " -> Đang cài đặt Antigravity CLI..." -ForegroundColor Cyan
        try {
            irm https://antigravity.google/install.ps1 | iex
            Write-Host " -> Cài đặt Antigravity CLI hoàn tất!" -ForegroundColor Green
        } catch {
            Write-Host " -> Không thể tải tự động agy. Bạn có thể cài tại: https://antigravity.google" -ForegroundColor DarkYellow
        }
    }

    # 5.3. OpenAI Codex CLI
    if (Get-Command codex.exe -ErrorAction SilentlyContinue) {
        Write-Host " -> OpenAI Codex CLI: [ĐÃ CÀI ĐẶT]" -ForegroundColor Green
    } else {
        Write-Host " -> Đang cài đặt OpenAI Codex..." -ForegroundColor Cyan
        winget install --id OpenAI.Codex --source winget --silent --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) {
            npm install -g @openai/codex 2>$null
        }
    }

    # 5.4. Google Cloud Code / Cloud SDK
    if (Get-Command gcloud.cmd, gcloud.exe -ErrorAction SilentlyContinue) {
        Write-Host " -> Google Cloud Code / SDK: [ĐÃ CÀI ĐẶT]" -ForegroundColor Green
    } else {
        Write-Host " -> Đang cài đặt Google Cloud SDK (Cloud Code)..." -ForegroundColor Cyan
        winget install --id Google.CloudSDK --source winget --silent --accept-package-agreements --accept-source-agreements
    }

    # 5.5. OpenCode CLI
    if (Get-Command opencode -ErrorAction SilentlyContinue) {
        Write-Host " -> OpenCode: [ĐÃ CÀI ĐẶT]" -ForegroundColor Green
    } else {
        Write-Host " -> Đang cài đặt OpenCode..." -ForegroundColor Cyan
        pip install opencode-ai 2>$null
        if ($LASTEXITCODE -ne 0) {
            npm install -g opencode-ai 2>$null
        }
    }

    Write-Host "`n[💡 HƯỚNG DẪN XÁC THỰC TÀI KHOẢN SAU KHI CÀI ĐẶT]" -ForegroundColor Yellow
    Write-Host " - Antigravity: Chạy 'agy' để đăng nhập tài khoản Google AI Pro." -ForegroundColor Cyan
    Write-Host " - OpenAI Codex: Chạy 'codex login' để xác thực tài khoản OpenAI." -ForegroundColor Cyan
    Write-Host " - Google Cloud Code: Chạy 'gcloud auth login' để đăng nhập." -ForegroundColor Cyan
} else {
    Write-Host " -> Đã bỏ qua cài đặt công cụ AI." -ForegroundColor Green
}

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host " HOÀN TẤT SETUP! BẠN ĐÃ SẴN SÀNG LÀM VIỆC." -ForegroundColor Green
Write-Host " - Mở WezTerm lên và bắt đầu code." -ForegroundColor Green
Write-Host " - Phím chuyển ô WezTerm: Alt + Mũi tên hoặc Alt + h/j/k/l." -ForegroundColor Green
if ($hasWSL) {
    Write-Host " - Để mở Tmux: gõ 'wsl' rồi gõ 'tmux'." -ForegroundColor Green
}
Write-Host "==========================================================" -ForegroundColor Cyan
