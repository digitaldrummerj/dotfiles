# ================================================================
# POWERSHELL PROFILE - MODULAR CONFIGURATION
# ================================================================
# This profile provides shortcuts and tools for:
# - Obvio project management (oea, oew, oma, etc.)
# - Git, Docker, and Copilot CLI shortcuts
# - Directory navigation and bookmarks
# - System utilities and developer tools
# ================================================================

# ================================================================
# ENVIRONMENT SETUP
# ================================================================

# Initialize Homebrew environment variables
$(/opt/homebrew/bin/brew shellenv) | Invoke-Expression

# Load PowerShell modules
Import-Module Terminal-Icons  # Pretty icons for files/folders
Import-Module PSReadLine      # Enhanced command-line editing

# Load sensitive environment variables from macOS Keychain
# This keeps secrets out of plain text files and syncs across profile updates
$keychainEnvVars = @('GITHUB_GIST_TOKEN', 'POWERSHELL_PRIVATE_GIST_ID')
foreach ($varName in $keychainEnvVars) {
  if (-not (Get-Item -Path "Env:$varName" -ErrorAction SilentlyContinue)) {
    try {
      # Retrieve from keychain using security command
      $value = & security find-generic-password -a "$env:USER" -s "pwsh-env-$varName" -w 2>$null
      if ($LASTEXITCODE -eq 0 -and $value) {
        [System.Environment]::SetEnvironmentVariable($varName, $value, [System.EnvironmentVariableTarget]::Process)
      }
    }
    catch {
      # Silently ignore if not found in keychain
    }
  }
}

# Validate required environment variables are set
$missingEnvVars = @()
if (-not $env:GITHUB_GIST_TOKEN) { $missingEnvVars += "GITHUB_GIST_TOKEN" }
if (-not $env:POWERSHELL_PRIVATE_GIST_ID) { $missingEnvVars += "POWERSHELL_PRIVATE_GIST_ID" }

if ($missingEnvVars.Count -gt 0) {
  Write-Host "Missing environment variables: $($missingEnvVars -join ', ')" -ForegroundColor Yellow
  Write-Host "Set them using: SetEnv 'VARIABLE_NAME' 'your-value-here'" -ForegroundColor Cyan
}

# Configure PSReadLine for better command-line experience
Set-PSReadLineOption -PredictionSource History      # Suggest commands from history
Set-PSReadLineOption -PredictionViewStyle ListView  # Show suggestions in a list
Set-PSReadLineOption -EditMode Windows              # Use Windows-style editing keys

# Initialize oh-my-posh prompt theme
# Load config first to get theme path
. "$PSScriptRoot/modules/config.ps1"
oh-my-posh init pwsh --config $script:themePath | Invoke-Expression

# Initialize Fast Node Manager (fnm) for Node.js version management
fnm env --use-on-cd | Out-String | Invoke-Expression

# ================================================================
# LOAD MODULES
# ================================================================
# Load modules in order (some modules depend on previous ones)

. "$PSScriptRoot/modules/dependencies.ps1"      # Check required tools

# Load private modules (from git submodule) if they exist
$privateModulesPath = Join-Path $PSScriptRoot "private-modules/powershell/modules"
if (Test-Path $privateModulesPath) {
  Get-ChildItem -Path $privateModulesPath -Filter "*.ps1" -File | ForEach-Object {
    . $_.FullName
  }
}

. "$PSScriptRoot/modules/companion.ps1"         # Companion module management
. "$PSScriptRoot/modules/navigation.ps1"        # Folder navigation & bookmarks
. "$PSScriptRoot/modules/package-npm.ps1"       # npm shortcuts
. "$PSScriptRoot/modules/package-yarn.ps1"      # yarn shortcuts
. "$PSScriptRoot/modules/package-fnm.ps1"       # fnm (Fast Node Manager) shortcuts
. "$PSScriptRoot/modules/package-install.ps1"   # Smart package install (auto-detect npm/yarn)
. "$PSScriptRoot/modules/git-shortcuts.ps1"     # Git shortcuts
. "$PSScriptRoot/modules/copilot-shortcuts.ps1" # Copilot CLI shortcuts
. "$PSScriptRoot/modules/docker-shortcuts.ps1"  # Docker shortcuts
. "$PSScriptRoot/modules/docker-compose-shortcuts.ps1" # Docker Compose shortcuts
. "$PSScriptRoot/modules/zoomiso.ps1"           # ZoomISO production control
. "$PSScriptRoot/modules/profile-sync.ps1"      # Profile sync with GitHub Gist
. "$PSScriptRoot/modules/utilities.ps1"         # Utility functions & developer tools
. "$PSScriptRoot/modules/help.ps1"              # Help system & startup banner




# Display ASCII art banner
Write-Host "     " -NoNewline
Write-Host "_____" -ForegroundColor Red
Write-Host "    /" -NoNewline -ForegroundColor Red
Write-Host "     " -NoNewline -ForegroundColor Gray
Write-Host "`\     " -NoNewline -ForegroundColor Red
Write-Host "LET YOUR NERD" -ForegroundColor Red
Write-Host "   " -NoNewline
Write-Host "| " -NoNewline -ForegroundColor Red
Write-Host "[" -NoNewline -ForegroundColor Red
Write-Host "O" -NoNewline -ForegroundColor White
Write-Host "_" -NoNewline -ForegroundColor Red
Write-Host "O" -NoNewline -ForegroundColor White
Write-Host "]" -NoNewline -ForegroundColor Red
Write-Host " |    " -NoNewline -ForegroundColor Red
Write-Host "BE HEARD" -ForegroundColor White
Write-Host "   " -NoNewline
Write-Host "|   " -NoNewline -ForegroundColor Red
Write-Host ">" -NoNewline -ForegroundColor Gray
Write-Host "   |    " -ForegroundColor Red
Write-Host "    " -NoNewline
Write-Host "`\_____" -NoNewline -ForegroundColor Red
Write-Host "/     " -NoNewline -ForegroundColor Red
Write-Host "turning virtual events into extraordinary experiences" -ForegroundColor DarkGray
Write-Host "       " -NoNewline
Write-Host "|" -ForegroundColor Red
Write-Host ""
Write-Host "✨ PowerShell profile loaded! Type 'help' for available shortcuts and features" -ForegroundColor Green








