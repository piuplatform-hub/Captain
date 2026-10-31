<#
.SYNOPSIS
    Automated dev environment setup: WezTerm, Neovim (LazyVim), WSL & Tmux, with optional AI Coding Tools.
.DESCRIPTION
    Installs packages via Winget, configures WezTerm, Neovim, WSL/Tmux, and AI tools (Antigravity, Claude Code, Codex, CloudCode, OpenCode).
    Supports direct one-liner execution from GitHub.
.PARAMETER InstallWSL
    Automatically install WSL without prompt.
.PARAMETER SkipWSL
    Skip WSL installation and checks.
.PARAMETER WithAI
    Automatically install all AI Coding tools (Antigravity, Claude Code, Codex, CloudCode, OpenCode).
.PARAMETER SkipAI
    Skip AI tools installation.
#>

param(
    [switch]$InstallWSL,
    [switch]$SkipWSL,
    [switch]$WithAI,
    [switch]$SkipAI
)

$ErrorActionPreference = "Continue"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " STARTING DEVELOPMENT ENVIRONMENT SETUP (CAPTAIN)" -ForegroundColor Green
Write-Host " (WezTerm + Neovim LazyVim + WSL + Tmux + AI Tools)" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan

# ---------------------------------------------------------------------
# AUTO-DETECT RUN FROM GITHUB OR LOCAL DIRECTORY
# ---------------------------------------------------------------------
if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "wezterm\.wezterm.lua"))) {
    $DotfilesDir = $PSScriptRoot
} else {
    $DotfilesDir = Join-Path $HOME "dotfiles"
    if (-not (Test-Path (Join-Path $DotfilesDir "wezterm\.wezterm.lua"))) {
        Write-Host "`n[Direct run from GitHub detected]" -ForegroundColor Cyan
        Write-Host "Preparing dotfiles directory at: $DotfilesDir..." -ForegroundColor Yellow

        # 1. Ensure Git is installed
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Write-Host "Git not found. Installing Git via Winget..." -ForegroundColor Cyan
            winget install --id Git.Git --source winget --silent --accept-package-agreements --accept-source-agreements
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        }

        # 2. Clone or download ZIP from GitHub
        Write-Host "Downloading Captain repository..." -ForegroundColor Cyan
        try {
            git clone https://github.com/piuplatform-hub/Captain.git $DotfilesDir
        } catch {
            Write-Host "Git clone failed, downloading ZIP archive directly..." -ForegroundColor Yellow
            $zipPath = "$HOME\captain.zip"
            Invoke-WebRequest -Uri "https://github.com/piuplatform-hub/Captain/archive/refs/heads/main.zip" -OutFile $zipPath -UseBasicParsing
            Expand-Archive -Path $zipPath -DestinationPath "$HOME\captain_temp" -Force
            if (Test-Path $DotfilesDir) { Remove-Item -Path $DotfilesDir -Recurse -Force -ErrorAction SilentlyContinue }
            Move-Item -Path "$HOME\captain_temp\Captain-main" -Destination $DotfilesDir -Force
            Remove-Item -Path $zipPath, "$HOME\captain_temp" -Recurse -Force -ErrorAction SilentlyContinue
        }
    } else {
        Write-Host "`nFound Captain repository at $DotfilesDir, syncing latest version..." -ForegroundColor Cyan
        git -C $DotfilesDir pull origin main 2>$null
    }
}

# ---------------------------------------------------------------------
# 1. CORE TOOLS VIA WINGET
# ---------------------------------------------------------------------
$packages = @(
    @{ Name = "Git"; Id = "Git.Git" },
    @{ Name = "WezTerm"; Id = "wez.wezterm" },
    @{ Name = "Neovim"; Id = "Neovim.Neovim" },
    @{ Name = "Ripgrep (Fast code search for Neovim)"; Id = "BurntSushi.ripgrep.MSVC" },
    @{ Name = "Fd (Fast file search for Neovim)"; Id = "sharkdp.fd" }
)

Write-Host "`n[1/5] Checking core tools via Winget..." -ForegroundColor Yellow
foreach ($pkg in $packages) {
    Write-Host "Checking $($pkg.Name)... " -NoNewline
    $check = winget list --id $pkg.Id --source winget --exact 2>$null
    if ($LASTEXITCODE -eq 0 -and ($check -match [regex]::Escape($pkg.Id))) {
        Write-Host "[INSTALLED]" -ForegroundColor Green
    } else {
        Write-Host "[INSTALLING...]" -ForegroundColor Cyan
        winget install --id $pkg.Id --source winget --silent --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -eq 0) {
            Write-Host " -> Successfully installed $($pkg.Name)!" -ForegroundColor Green
        } else {
            Write-Host " -> Could not install $($pkg.Name) via Winget." -ForegroundColor Red
        }
    }
}

# ---------------------------------------------------------------------
# 2. WEZTERM CONFIGURATION
# ---------------------------------------------------------------------
Write-Host "`n[2/5] Setting up WezTerm configuration..." -ForegroundColor Yellow
$weztermSrc = Join-Path $DotfilesDir "wezterm\.wezterm.lua"
$weztermDest = Join-Path $HOME ".wezterm.lua"

if (Test-Path $weztermSrc) {
    Copy-Item -Path $weztermSrc -Destination $weztermDest -Force
    Write-Host " -> Copied WezTerm config to: $weztermDest" -ForegroundColor Green
} else {
    Write-Host " -> File wezterm\.wezterm.lua not found!" -ForegroundColor Red
}

# ---------------------------------------------------------------------
# 3. NEOVIM (LAZYVIM) CONFIGURATION
# ---------------------------------------------------------------------
Write-Host "`n[3/5] Setting up Neovim (LazyVim) on Windows..." -ForegroundColor Yellow
$nvimSrc = Join-Path $DotfilesDir "nvim"
$nvimDest = Join-Path $env:LOCALAPPDATA "nvim"

if (Test-Path $nvimSrc) {
    if (Test-Path $nvimDest) {
        $backupDest = "$nvimDest.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Write-Host " -> Backing up existing nvim config to: $backupDest" -ForegroundColor DarkGray
        Move-Item -Path $nvimDest -Destination $backupDest -Force
    }
    Copy-Item -Path $nvimSrc -Destination $nvimDest -Recurse -Force
    Write-Host " -> Copied Neovim configuration to: $nvimDest" -ForegroundColor Green
} else {
    Write-Host " -> Directory nvim not found!" -ForegroundColor Red
}

# ---------------------------------------------------------------------
# 4. WSL & TMUX SETUP
# ---------------------------------------------------------------------
Write-Host "`n[4/5] Checking WSL and Tmux environment..." -ForegroundColor Yellow

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
    Write-Host " -> WSL (Windows Subsystem for Linux) is NOT currently installed." -ForegroundColor Yellow
    
    $shouldInstallWSL = $false
    if ($SkipWSL) {
        Write-Host " -> Skipping WSL setup per -SkipWSL flag." -ForegroundColor DarkGray
    } elseif ($InstallWSL) {
        $shouldInstallWSL = $true
    } else {
        Write-Host "`n[?] Tmux requires Linux (WSL). Do you want to automatically install WSL (Ubuntu)? (Y/N): " -ForegroundColor Cyan -NoNewline
        $resp = Read-Host
        if ($resp -match "^[yY]") {
            $shouldInstallWSL = $true
        }
    }

    if ($shouldInstallWSL) {
        Write-Host " -> Requesting Administrator privilege to install WSL and Ubuntu..." -ForegroundColor Cyan
        $wslCmd = "wsl.exe --install -d Ubuntu --no-launch; Write-Host 'Press any key to close...' -ForegroundColor Green; [Console]::ReadKey()"
        Start-Process powershell.exe -ArgumentList "-NoProfile -Command `"$wslCmd`"" -Verb RunAs -Wait

        Write-Host "`n[! IMPORTANT NOTICE FOR WSL !]" -ForegroundColor Yellow
        Write-Host "First-time WSL installation requires a computer restart (Restart Windows)." -ForegroundColor Yellow
        Write-Host "After restarting, re-run this install script to finish Tmux configuration." -ForegroundColor Cyan
    } else {
        Write-Host " -> Skipped WSL. WezTerm and Neovim work great natively on Windows!" -ForegroundColor Green
    }
} else {
    Write-Host " -> WSL is active and detected!" -ForegroundColor Green
    
    Write-Host " -> Installing Tmux inside WSL..." -ForegroundColor Cyan
    try {
        wsl -u root -- bash -c "apt-get update -qq && apt-get install -y -qq tmux"
        Write-Host " -> Successfully installed Tmux inside WSL!" -ForegroundColor Green
    } catch {
        Write-Host " -> Could not install tmux automatically via apt." -ForegroundColor DarkYellow
    }

    if (Test-Path $tmuxSrc) {
        Write-Host " -> Syncing .tmux.conf into WSL..." -ForegroundColor Cyan
        Get-Content $tmuxSrc -Raw | wsl bash -c "cat > ~/.tmux.conf"
        Write-Host " -> Copied .tmux.conf into WSL!" -ForegroundColor Green
    }

    Write-Host " -> Syncing Neovim config into WSL..." -ForegroundColor Cyan
    wsl bash -c "mkdir -p ~/.config/nvim"
    $wslNvimPath = wsl bash -c "wslpath -u '$nvimSrc'"
    if ($wslNvimPath) {
        wsl bash -c "cp -r $wslNvimPath/* ~/.config/nvim/ 2>/dev/null"
        Write-Host " -> Synced Neovim config to ~/.config/nvim in WSL!" -ForegroundColor Green
    }
}

# ---------------------------------------------------------------------
# 5. AI CODING ASSISTANTS SUITE
# (Antigravity, Claude Code, OpenAI Codex, Cloud Code, OpenCode)
# ---------------------------------------------------------------------
Write-Host "`n[5/5] Checking AI Coding Tools (Antigravity, Claude Code, Codex, CloudCode, OpenCode)..." -ForegroundColor Yellow

$shouldInstallAI = $false
if ($SkipAI) {
    Write-Host " -> Skipping AI tools per -SkipAI flag." -ForegroundColor DarkGray
} elseif ($WithAI) {
    $shouldInstallAI = $true
} else {
    Write-Host "`n[?] Do you want to install AI Coding Tools (Antigravity, Claude Code, Codex, CloudCode, OpenCode)? (Y/N): " -ForegroundColor Cyan -NoNewline
    $respAI = Read-Host
    if ($respAI -match "^[yY]") {
        $shouldInstallAI = $true
    }
}

if ($shouldInstallAI) {
    Write-Host "`n--- STARTING AI CODING TOOLS INSTALLATION ---" -ForegroundColor Cyan

    # 5.1. Runtime requirement: Node.js LTS
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Write-Host " -> Installing Node.js LTS (foundation for AI CLIs)..." -ForegroundColor Cyan
        winget install --id OpenJS.NodeJS.LTS --source winget --silent --accept-package-agreements --accept-source-agreements
    }

    # 5.2. Antigravity CLI (agy)
    if (Get-Command agy.exe -ErrorAction SilentlyContinue) {
        Write-Host " -> Antigravity CLI (agy): [INSTALLED]" -ForegroundColor Green
    } else {
        Write-Host " -> Installing Antigravity CLI..." -ForegroundColor Cyan
        try {
            irm https://antigravity.google/cli/install.ps1 | iex
            Write-Host " -> Antigravity CLI installation finished!" -ForegroundColor Green
        } catch {
            Write-Host " -> Could not auto-download agy. Visit: https://antigravity.google" -ForegroundColor DarkYellow
        }
    }

    # 5.3. Claude Code CLI (Anthropic)
    if (Get-Command claude.cmd, claude.exe, claude -ErrorAction SilentlyContinue) {
        Write-Host " -> Claude Code CLI: [INSTALLED]" -ForegroundColor Green
    } else {
        Write-Host " -> Installing Claude Code CLI (@anthropic-ai/claude-code)..." -ForegroundColor Cyan
        npm install -g @anthropic-ai/claude-code 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host " -> Claude Code CLI installation finished!" -ForegroundColor Green
        } else {
            Write-Host " -> Could not auto-install Claude Code. You can run manually: npm install -g @anthropic-ai/claude-code" -ForegroundColor DarkYellow
        }
    }

    # 5.4. OpenAI Codex CLI
    if (Get-Command codex.exe -ErrorAction SilentlyContinue) {
        Write-Host " -> OpenAI Codex CLI: [INSTALLED]" -ForegroundColor Green
    } else {
        Write-Host " -> Installing OpenAI Codex..." -ForegroundColor Cyan
        winget install --id OpenAI.Codex --source winget --silent --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) {
            npm install -g @openai/codex 2>$null
        }
    }

    # 5.5. Google Cloud Code / Cloud SDK
    if (Get-Command gcloud.cmd, gcloud.exe -ErrorAction SilentlyContinue) {
        Write-Host " -> Google Cloud Code / SDK: [INSTALLED]" -ForegroundColor Green
    } else {
        Write-Host " -> Installing Google Cloud SDK (Cloud Code)..." -ForegroundColor Cyan
        winget install --id Google.CloudSDK --source winget --silent --accept-package-agreements --accept-source-agreements
    }

    # 5.6. OpenCode CLI
    if (Get-Command opencode -ErrorAction SilentlyContinue) {
        Write-Host " -> OpenCode: [INSTALLED]" -ForegroundColor Green
    } else {
        Write-Host " -> Installing OpenCode..." -ForegroundColor Cyan
        pip install opencode-ai 2>$null
        if ($LASTEXITCODE -ne 0) {
            npm install -g opencode-ai 2>$null
        }
    }

    Write-Host "`n[AUTHENTICATION QUICK GUIDE]" -ForegroundColor Yellow
    Write-Host " - Antigravity: Run 'agy' to log in with your Google account." -ForegroundColor Cyan
    Write-Host " - Claude Code: Run 'claude' to log in with your Anthropic account." -ForegroundColor Cyan
    Write-Host " - OpenAI Codex: Run 'codex login' to authenticate OpenAI." -ForegroundColor Cyan
    Write-Host " - Google Cloud Code: Run 'gcloud auth login' to authenticate." -ForegroundColor Cyan
} else {
    Write-Host " -> Skipped AI tools installation." -ForegroundColor Green
}

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host " SETUP COMPLETE! YOU ARE READY TO CODE." -ForegroundColor Green
Write-Host " - Open WezTerm and start coding." -ForegroundColor Green
Write-Host " - Split navigation in WezTerm: Alt + Arrows or Alt + h/j/k/l." -ForegroundColor Green
if ($hasWSL) {
    Write-Host " - To open Tmux: run 'wsl' then run 'tmux'." -ForegroundColor Green
}
Write-Host "==========================================================" -ForegroundColor Cyan
