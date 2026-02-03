#!/usr/bin/env pwsh
# ================================================================
# DEPLOY SCRIPT - Sync PowerShell files between Git repo and active profile
# ================================================================
# Usage: 
#   pwsh ./deploy.ps1                  # Deploy: Git → Active Profile
#   pwsh ./deploy.ps1 --from-profile   # Sync back: Active Profile → Git
#
# Purpose:
#   - Git → Profile: Deploy changes from Git repo to test locally
#   - Profile → Git: Sync quick edits back to Git for commit
# ================================================================

param(
    [switch]$FromProfile
)

$ErrorActionPreference = "Stop"

# Define paths
$gitRepoPath = $PSScriptRoot
$activeProfilePath = Join-Path $HOME ".config/powershell"

# Files/directories to exclude from copying
$excludePatterns = @(
    ".git",
    ".gitignore", 
    ".gitmodules",
    ".ignored-dependencies.json",
    "backup*",
    "deploy*.ps1",
    ".DS_Store",
    "Thumbs.db",
    "docs",
    ".github"
)

# Determine direction
if ($FromProfile) {
    $sourcePath = $activeProfilePath
    $destPath = $gitRepoPath
    $direction = "Active Profile → Git Repo"
    $createBackup = $false
}
else {
    $sourcePath = $gitRepoPath
    $destPath = $activeProfilePath
    $direction = "Git Repo → Active Profile"
    $createBackup = $true
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "PowerShell Profile Deployment" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Direction: $direction" -ForegroundColor Cyan
Write-Host "Source:    $sourcePath" -ForegroundColor Gray
Write-Host "Dest:      $destPath" -ForegroundColor Gray
Write-Host ""

# Verify paths exist
if (-not (Test-Path $sourcePath)) {
    Write-Host "❌ Source directory does not exist: $sourcePath" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $destPath)) {
    Write-Host "❌ Destination directory does not exist: $destPath" -ForegroundColor Red
    if ($FromProfile) {
        Write-Host "   Hint: Clone the Git repository first" -ForegroundColor Yellow
    }
    else {
        Write-Host "   Hint: Run install.ps1 to set up the profile first" -ForegroundColor Yellow
    }
    exit 1
}

# Create backup if deploying to active profile
if ($createBackup) {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupParent = Join-Path $destPath "backup"
    $backupPath = Join-Path $backupParent $timestamp
    
    Write-Host "Creating backup..." -ForegroundColor Yellow
    Write-Host "  Backup: backup/$timestamp" -ForegroundColor Gray
    Write-Host ""
    
    try {
        # Create backup directory
        New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
        
        # Backup current profile
        if (Test-Path $PROFILE) {
            Copy-Item -Path $PROFILE -Destination (Join-Path $backupPath (Split-Path -Leaf $PROFILE)) -Force
            Write-Host "  ✓ Backed up profile" -ForegroundColor Gray
        }
        
        # Backup modules directory (entire directory with all subdirectories)
        $modulesDir = Join-Path $destPath 'modules'
        if (Test-Path $modulesDir) {
            $backupModulesDir = Join-Path $backupPath 'modules'
            Copy-Item -Path $modulesDir -Destination $backupModulesDir -Recurse -Force
            Write-Host "  ✓ Backed up modules/" -ForegroundColor Gray
        }
        
        # Backup scripts directory (entire directory)
        $scriptsDir = Join-Path $destPath 'scripts'
        if (Test-Path $scriptsDir) {
            $backupScriptsDir = Join-Path $backupPath 'scripts'
            Copy-Item -Path $scriptsDir -Destination $backupScriptsDir -Recurse -Force
            Write-Host "  ✓ Backed up scripts/" -ForegroundColor Gray
        }
        
        # Backup private-modules directory (entire directory with submodules)
        $privateModulesDir = Join-Path $destPath 'private-modules'
        if (Test-Path $privateModulesDir) {
            $backupPrivateDir = Join-Path $backupPath 'private-modules'
            Copy-Item -Path $privateModulesDir -Destination $backupPrivateDir -Recurse -Force
            Write-Host "  ✓ Backed up private-modules/" -ForegroundColor Gray
        }
        
        # Backup theme
        $themePath = Join-Path $destPath 'theme.omp.json'
        if (Test-Path $themePath) {
            Copy-Item -Path $themePath -Destination (Join-Path $backupPath 'theme.omp.json') -Force
            Write-Host "  ✓ Backed up theme" -ForegroundColor Gray
        }
        
        # Backup bookmarks
        $bookmarksPath = Join-Path $destPath 'bookmarks.json'
        if (Test-Path $bookmarksPath) {
            Copy-Item -Path $bookmarksPath -Destination (Join-Path $backupPath 'bookmarks.json') -Force
            Write-Host "  ✓ Backed up bookmarks" -ForegroundColor Gray
        }
        
        # Backup other root files (README, install.ps1, etc.)
        $otherFiles = Get-ChildItem -Path $destPath -File | Where-Object { 
            $_.Name -ne 'Microsoft.PowerShell_profile.ps1' -and
            $_.Name -ne 'theme.omp.json' -and
            $_.Name -ne 'bookmarks.json' -and
            $_.Name -ne '.sync-state.json' -and
            $_.Name -ne '.ignored-dependencies.json' -and
            $_.Name -ne '.DS_Store'
        }
        if ($otherFiles.Count -gt 0) {
            foreach ($file in $otherFiles) {
                Copy-Item -Path $file.FullName -Destination (Join-Path $backupPath $file.Name) -Force
            }
            Write-Host "  ✓ Backed up $($otherFiles.Count) other file(s)" -ForegroundColor Gray
        }
        
        Write-Host ""
        Write-Host "✓ Backup created successfully" -ForegroundColor Green
        Write-Host ""
    }
    catch {
        Write-Host "❌ Failed to create backup: $_" -ForegroundColor Red
        exit 1
    }
}

# Copy files
Write-Host "Copying files..." -ForegroundColor Yellow
Write-Host ""

$copiedCount = 0
$skippedCount = 0

try {
    # Get all items in source directory (excluding backup directories)
    $items = Get-ChildItem -Path $sourcePath -Force | Where-Object { 
        $_.Name -ne "backup" -and $_.Name -notlike "backup-*" 
    }
    
    foreach ($item in $items) {
        $relativeName = $item.Name
        
        # Check if item should be excluded
        $shouldExclude = $false
        foreach ($pattern in $excludePatterns) {
            if ($relativeName -like $pattern -or $relativeName -eq $pattern) {
                $shouldExclude = $true
                break
            }
        }
        
        if ($shouldExclude) {
            Write-Host "  ⊝ Skipped: $relativeName" -ForegroundColor DarkGray
            $skippedCount++
            continue
        }
        
        # Handle special case: profile.ps1 ↔ Microsoft.PowerShell_profile.ps1 mapping
        if ($FromProfile) {
            # Syncing FROM active profile TO Git repo
            if ($relativeName -eq "Microsoft.PowerShell_profile.ps1") {
                # Copy Microsoft.PowerShell_profile.ps1 → profile.ps1 in Git
                $sourceFile = Join-Path $sourcePath "Microsoft.PowerShell_profile.ps1"
                $destFile = Join-Path $destPath "profile.ps1"
                Copy-Item -Path $sourceFile -Destination $destFile -Force
                Write-Host "  ✓ Copied: Microsoft.PowerShell_profile.ps1 → profile.ps1" -ForegroundColor Green
                $copiedCount++
                continue
            }
            
            # Skip profile.ps1 if it exists in active profile (shouldn't, but just in case)
            if ($relativeName -eq "profile.ps1") {
                Write-Host "  ⊝ Skipped: profile.ps1 (use Microsoft.PowerShell_profile.ps1 instead)" -ForegroundColor DarkGray
                $skippedCount++
                continue
            }
        }
        else {
            # Deploying FROM Git TO active profile
            if ($relativeName -eq "profile.ps1") {
                # Copy profile.ps1 → Microsoft.PowerShell_profile.ps1 in active profile
                $sourceFile = Join-Path $sourcePath "profile.ps1"
                $destFile = Join-Path $destPath "Microsoft.PowerShell_profile.ps1"
                Copy-Item -Path $sourceFile -Destination $destFile -Force
                Write-Host "  ✓ Copied: profile.ps1 → Microsoft.PowerShell_profile.ps1" -ForegroundColor Green
                $copiedCount++
                continue
            }
        }
        
        # Copy item
        $destItemPath = Join-Path $destPath $relativeName
        
        if ($item.PSIsContainer) {
            # For directories: Copy contents (not the directory itself) to avoid nesting
            # Source: /git/modules/*  -> Destination: ~/.config/powershell/modules/
            if (-not (Test-Path $destItemPath)) {
                New-Item -ItemType Directory -Path $destItemPath -Force | Out-Null
            }
            Copy-Item -Path (Join-Path $item.FullName "*") -Destination $destItemPath -Recurse -Force
            Write-Host "  ✓ Copied: $relativeName/ (directory)" -ForegroundColor Green
        } else {
            # For files: Copy directly
            Copy-Item -Path $item.FullName -Destination $destItemPath -Force
            Write-Host "  ✓ Copied: $relativeName" -ForegroundColor Green
        }
        
        $copiedCount++
    }
}
catch {
    Write-Host ""
    Write-Host "❌ Copy failed: $_" -ForegroundColor Red
    exit 1
}

# Success message
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "✅ Deployment Complete!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor White
Write-Host "  Copied:  $copiedCount items" -ForegroundColor Green
Write-Host "  Skipped: $skippedCount items" -ForegroundColor Gray
Write-Host ""

# Next steps
Write-Host "Next Steps:" -ForegroundColor Cyan

if ($FromProfile) {
    Write-Host "  1. Review changes:  git status" -ForegroundColor White
    Write-Host "  2. Stage changes:   git add ." -ForegroundColor White
    Write-Host "  3. Commit changes:  git commit -m 'Your message'" -ForegroundColor White
    Write-Host "  4. Push to GitHub:  git push" -ForegroundColor White
}
else {
    Write-Host "  1. Restart PowerShell terminal to test changes" -ForegroundColor White
    Write-Host "  2. If satisfied, run: profile ps" -ForegroundColor White
    Write-Host "  3. Then commit and push to Git: git add . && git commit && git push" -ForegroundColor White
}

Write-Host ""
