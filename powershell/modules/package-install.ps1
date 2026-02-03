# ================================================================
# SMART PACKAGE INSTALL
# ================================================================
# Auto-detect npm or yarn based on lock files
# Usage:
#   install       → auto-detect and install
#   install -f    → auto-detect and clean install
# ================================================================

<#
.SYNOPSIS
    Smart package install - auto-detects npm or yarn
.DESCRIPTION
    Automatically detects which package manager to use based on lock files:
    - package-lock.json → npm install
    - yarn.lock → yarn install
    - Both present → error (ambiguous)
    - Neither present → defaults to npm
    With -Force flag, uses clean install (npm ci or yarn install --frozen-lockfile)
.PARAMETER Force
    Use clean install (npm ci or yarn install --frozen-lockfile)
.EXAMPLE
    install      # Auto-detect and install
    install -f   # Auto-detect and clean install
.ALIAS
    install
#>
function Install-Packages {
  [Alias('install')]
  Param(
    [Parameter(Mandatory = $false)]
    [Alias('f')]
    [switch]$Force
  )

  $hasPackageLock = Test-Path "package-lock.json"
  $hasYarnLock = Test-Path "yarn.lock"

  # Error if both lock files exist
  if ($hasPackageLock -and $hasYarnLock) {
    Write-Error "Conflicting lock files found!"
    Write-Host "Both package-lock.json and yarn.lock exist in this directory." -ForegroundColor Red
    Write-Host "Please remove one of the lock files or specify the package manager:" -ForegroundColor Yellow
    Write-Host "  npm install     (for npm)" -ForegroundColor Cyan
    Write-Host "  yarn install    (for yarn)" -ForegroundColor Cyan
    return
  }

  if ($hasYarnLock) {
    if ($Force) {
      Write-Host "Running: yarn install --frozen-lockfile" -ForegroundColor Cyan
      yarn install --frozen-lockfile
    } else {
      Write-Host "Running: yarn install" -ForegroundColor Cyan
      yarn install
    }
  }
  elseif ($hasPackageLock) {
    if ($Force) {
      Write-Host "Running: npm ci" -ForegroundColor Cyan
      npm ci
    } else {
      Write-Host "Running: npm install" -ForegroundColor Cyan
      npm install
    }
  }
  else {
    Write-Warning "No lock file found (package-lock.json or yarn.lock)"
    Write-Host "Defaulting to npm install..." -ForegroundColor Yellow
    npm install
  }
}
