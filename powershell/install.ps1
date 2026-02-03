#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Install PowerShell profile from GitHub Gist
.DESCRIPTION
    This script sets up the PowerShell profile on a new machine by:
    - Creating the proper directory structure
    - Renaming flattened gist files (profile.ps1, modules-*, scripts-*)
    - Moving files to correct locations
    - Setting proper permissions
    - Installing required dependencies
.EXAMPLE
    ./install.ps1
    Run from the downloaded gist directory to install the profile
.EXAMPLE
    ./install.ps1 -SkipDependencies
    Install profile without checking/installing dependencies
.NOTES
    Gist files are flattened when downloaded:
    - profile.ps1 (not Microsoft.PowerShell_profile.ps1)
    - modules-*.ps1 (not in modules/ directory)
    - scripts-*.ps1 (not in scripts/ directory)
    This script handles the renaming and restructuring automatically.
#>

[CmdletBinding()]
param(
    [switch]$SkipDependencies,
    [switch]$Force
)

# ================================================================
# CONFIGURATION
# ================================================================

$script:TargetDir = Join-Path $HOME '.config' 'powershell'
$script:ModulesDir = Join-Path $script:TargetDir 'modules'
$script:ScriptsDir = Join-Path $script:TargetDir 'scripts'
$script:CurrentDir = Get-Location

# ================================================================
# HELPER FUNCTIONS
# ================================================================

function Write-Step {
    param([string]$Message)
    Write-Host "➜ $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "  ✓ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "  ⚠ $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "  ✗ $Message" -ForegroundColor Red
}

function Test-HasRequiredFiles {
    # Check if we have the essential gist files (flattened format with double-dash)
    # Gist downloads as: profile.ps1, modules--*.ps1, scripts--*.ps1
    $profileExists = Test-Path (Join-Path $script:CurrentDir 'profile.ps1')
    $hasModuleConfig = Test-Path (Join-Path $script:CurrentDir 'modules--config.ps1')
    $hasModuleHelp = Test-Path (Join-Path $script:CurrentDir 'modules--help.ps1')
    
    return ($profileExists -and $hasModuleConfig -and $hasModuleHelp)
}

# ================================================================
# MAIN INSTALLATION
# ================================================================

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  POWERSHELL PROFILE INSTALLER" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Check if we have required files
if (-not (Test-HasRequiredFiles)) {
    Write-Error "Required gist files not found!"
    Write-Host ""
    Write-Host "Please ensure you're running this script from the directory containing:" -ForegroundColor Yellow
    Write-Host "  • profile.ps1 (the main profile)" -ForegroundColor Gray
    Write-Host "  • modules--*.ps1 (module files with double-dash)" -ForegroundColor Gray
    Write-Host "  • scripts--*.ps1 (script files with double-dash)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "These files are created when you download the gist from GitHub." -ForegroundColor Gray
    Write-Host ""
    exit 1
}

Write-Success "Found gist files in current directory"
Write-Host ""

# Check if profile already exists
if ((Test-Path $script:TargetDir) -and -not $Force) {
    Write-Warning "Profile directory already exists: $script:TargetDir"
    Write-Host ""
    $response = Read-Host "Overwrite existing profile? (yes/no)"
    if ($response -ne 'yes') {
        Write-Host "Installation cancelled." -ForegroundColor Yellow
        exit 0
    }
    Write-Host ""
}

# ================================================================
# STEP 1: Create Directory Structure
# ================================================================

Write-Step "Creating directory structure..."

@($script:TargetDir, $script:ModulesDir, $script:ScriptsDir) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
        Write-Success "Created: $_"
    } else {
        Write-Success "Exists: $_"
    }
}

Write-Host ""

# ================================================================
# STEP 2: Install Main Profile
# ================================================================

Write-Step "Installing main profile..."

# Gist renames Microsoft.PowerShell_profile.ps1 → profile.ps1
$profileSource = Join-Path $script:CurrentDir 'profile.ps1'
# $PROFILE is already the full path to the target location
$profileTarget = $PROFILE

if (Test-Path $profileSource) {
    Copy-Item -Path $profileSource -Destination $profileTarget -Force
    Write-Success "Installed: $PROFILE"
} else {
    Write-Error "Profile file (profile.ps1) not found!"
}

Write-Host ""

# ================================================================
# STEP 3: Install Module Files
# ================================================================

Write-Step "Installing modules..."

# Find all modules--*.ps1 files (gist flattens directory structure with double-dash)
$moduleFiles = Get-ChildItem -Path $script:CurrentDir -Filter 'modules--*.ps1'

if ($moduleFiles.Count -eq 0) {
    Write-Warning "No module files found (modules--*.ps1)"
} else {
    foreach ($moduleFile in $moduleFiles) {
        # Remove 'modules--' prefix to get original filename
        $originalName = $moduleFile.Name -replace '^modules--', ''
        $target = Join-Path $script:ModulesDir $originalName
        
        Copy-Item -Path $moduleFile.FullName -Destination $target -Force
        Write-Success "Installed: modules/$originalName"
    }
    Write-Success "Installed $($moduleFiles.Count) module files"
}

Write-Host ""

# ================================================================
# STEP 4: Install Script Files
# ================================================================

Write-Step "Installing scripts..."

# Find all scripts--*.ps1 files (gist flattens directory structure with double-dash)
$scriptFiles = Get-ChildItem -Path $script:CurrentDir -Filter 'scripts--*.ps1'

if ($scriptFiles.Count -eq 0) {
    Write-Warning "No script files found (scripts--*.ps1)"
} else {
    foreach ($scriptFile in $scriptFiles) {
        # Remove 'scripts--' prefix to get original filename
        $originalName = $scriptFile.Name -replace '^scripts--', ''
        $target = Join-Path $script:ScriptsDir $originalName
        
        Copy-Item -Path $scriptFile.FullName -Destination $target -Force
        
        # Make executable on Unix-like systems
        if ($IsMacOS -or $IsLinux) {
            chmod +x $target
        }
        
        Write-Success "Installed: scripts/$originalName"
    }
    Write-Success "Installed $($scriptFiles.Count) script files"
}

Write-Host ""

# ================================================================
# STEP 5: Copy Additional Files
# ================================================================

Write-Step "Installing additional files..."

# Theme file
$themeSource = Join-Path $script:CurrentDir 'theme.omp.json'
$themeTarget = Join-Path $script:TargetDir 'theme.omp.json'
if (Test-Path $themeSource) {
    Copy-Item -Path $themeSource -Destination $themeTarget -Force
    Write-Success "Installed: theme.omp.json"
}

# Bookmarks file
$bookmarksSource = Join-Path $script:CurrentDir 'bookmarks.json'
$bookmarksTarget = Join-Path $script:TargetDir 'bookmarks.json'
if (Test-Path $bookmarksSource) {
    Copy-Item -Path $bookmarksSource -Destination $bookmarksTarget -Force
    Write-Success "Installed: bookmarks.json"
}

# README file
$readmeSource = Join-Path $script:CurrentDir 'README.md'
$readmeTarget = Join-Path $script:TargetDir 'README.md'
if (Test-Path $readmeSource) {
    Copy-Item -Path $readmeSource -Destination $readmeTarget -Force
    Write-Success "Installed: README.md"
}

# Install script (so it's available for future pulls)
$installSource = Join-Path $script:CurrentDir 'install.ps1'
$installTarget = Join-Path $script:TargetDir 'install.ps1'
if (Test-Path $installSource) {
    Copy-Item -Path $installSource -Destination $installTarget -Force
    Write-Success "Installed: install.ps1"
}

# Copy any custom files (files with -- that aren't modules or scripts)
$customFiles = Get-ChildItem -Path $script:CurrentDir -File | Where-Object {
    $name = $_.Name
    $name -like '*--*' -and 
    $name -notlike 'modules--*' -and 
    $name -notlike 'scripts--*'
}

if ($customFiles.Count -gt 0) {
    foreach ($customFile in $customFiles) {
        # Reconstruct directory path (e.g., custom--config.yaml -> custom/config.yaml)
        $relativePath = $customFile.Name -replace '--', '/'
        $targetPath = Join-Path $script:TargetDir $relativePath
        
        # Ensure parent directory exists
        $parentDir = Split-Path -Parent $targetPath
        if ($parentDir -and -not (Test-Path $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }
        
        Copy-Item -Path $customFile.FullName -Destination $targetPath -Force
        Write-Success "Installed: $relativePath"
    }
}

Write-Host ""

# ================================================================
# STEP 6: Check Dependencies
# ================================================================

if (-not $SkipDependencies) {
    Write-Step "Checking dependencies..."
    Write-Host ""
    
    # Check for oh-my-posh
    $hasPosh = Get-Command oh-my-posh -ErrorAction SilentlyContinue
    if ($hasPosh) {
        Write-Success "oh-my-posh: Installed"
    } else {
        Write-Warning "oh-my-posh: Not installed"
        Write-Host "    Install: brew install oh-my-posh" -ForegroundColor Gray
    }
    
    # Check for fnm
    $hasFnm = Get-Command fnm -ErrorAction SilentlyContinue
    if ($hasFnm) {
        Write-Success "fnm: Installed"
    } else {
        Write-Warning "fnm: Not installed"
        Write-Host "    Install: brew install fnm" -ForegroundColor Gray
    }
    
    # Check for GitHub CLI
    $hasGh = Get-Command gh -ErrorAction SilentlyContinue
    if ($hasGh) {
        Write-Success "GitHub CLI: Installed"
    } else {
        Write-Warning "GitHub CLI: Not installed"
        Write-Host "    Install: brew install gh" -ForegroundColor Gray
    }
    
    Write-Host ""
}

# ================================================================
# STEP 7: Setup Environment Variables
# ================================================================

Write-Step "Environment setup..."
Write-Host ""
Write-Warning "You need to set the following environment variables:"
Write-Host "  • GITHUB_GIST_TOKEN - For profile sync (store in Keychain)" -ForegroundColor Yellow
Write-Host "  • COMPANION_MODULE_DEV_ROOT - Path to companion modules" -ForegroundColor Yellow
Write-Host "  • OBVIO_DEV_ROOT - Path to Obvio projects" -ForegroundColor Yellow
Write-Host ""
Write-Host "After loading the profile, use:" -ForegroundColor Gray
Write-Host "  SetEnv 'GITHUB_GIST_TOKEN' 'your-token'" -ForegroundColor Cyan
Write-Host "  SetEnv 'COMPANION_MODULE_DEV_ROOT' '/path/to/companion-modules'" -ForegroundColor Cyan
Write-Host "  SetEnv 'OBVIO_DEV_ROOT' '/path/to/obvio'" -ForegroundColor Cyan
Write-Host ""

# ================================================================
# INSTALLATION COMPLETE
# ================================================================

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  ✓ INSTALLATION COMPLETE!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Close and reopen your terminal" -ForegroundColor White
Write-Host "  2. Set required environment variables (see above)" -ForegroundColor White
Write-Host "  3. Type 'help' to see all available commands" -ForegroundColor White
Write-Host ""
Write-Host "Profile location: $script:TargetDir" -ForegroundColor Gray
Write-Host ""
