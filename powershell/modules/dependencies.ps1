# ================================================================
# DEPENDENCY CHECK
# ================================================================
# Validates that required command-line tools are available
# Supports per-machine suppression via .ignored-dependencies.json

function Test-Dependencies {
  <#
  .SYNOPSIS
    Check for required command-line tools
  .DESCRIPTION
    Validates that common development tools are installed and shows warnings
    for any missing dependencies. Non-blocking - just informational.
    
    Suppression: Use 'profile ignore-dep <name>' to suppress specific warnings
  #>
  
  # Load ignored dependencies from file (machine-specific)
  $ignoredDepsPath = Join-Path $script:ProfileDir '.ignored-dependencies.json'
  $ignoredDeps = @()
  if (Test-Path $ignoredDepsPath) {
    try {
      $ignoredData = Get-Content $ignoredDepsPath -Raw | ConvertFrom-Json
      $ignoredDeps = $ignoredData.PSObject.Properties.Name
    } catch {
      # Silently fail if can't read file
    }
  }
  
  $dependencies = @{
    'gh'              = @{ Name = 'GitHub CLI'; InstallCmd = 'brew install gh'; Key = 'gh' }
    'git'             = @{ Name = 'Git'; InstallCmd = 'brew install git'; Key = 'git' }
    'docker'          = @{ Name = 'Docker'; InstallCmd = 'Install Docker Desktop'; Key = 'docker' }
    'fnm'             = @{ Name = 'Fast Node Manager'; InstallCmd = 'Install fnm'; Key = 'fnm' }
    'copilot'         = @{ Name = 'GitHub Copilot CLI'; InstallCmd = 'brew install copilot-cli'; Key = 'copilot' }
   
  }
  
  $missing = @()
  
  foreach ($cmd in $dependencies.Keys) {
    # Skip if ignored
    if ($ignoredDeps -contains $cmd) {
      continue
    }
    
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
      $missing += $dependencies[$cmd]
    }
  }
  
  # Check for Monaspace Nerd Font (cask installation)
  $fontMissing = $false
  if ($ignoredDeps -notcontains 'font') {
    $monaspiceCask = brew list --cask 2>&1 | Select-String -Pattern 'monaspice-nerd-font'
    $fontMissing = -not $monaspiceCask
    if ($fontMissing) {
      $missing += @{ Name = 'Monaspace Nerd Font'; InstallCmd = 'brew install --cask font-monaspice-nerd-font'; Key = 'font' }
    }
  }
  
  if ($missing.Count -gt 0) {
    Write-Host ""
    Write-Host "⚠️  Missing dependencies:" -ForegroundColor Yellow
    foreach ($dep in $missing) {
      Write-Host "   • $($dep.Name) - Install with: " -NoNewline -ForegroundColor Gray
      Write-Host "$($dep.InstallCmd)" -ForegroundColor Cyan
    }
    
    # Add reminder about font configuration if font is missing
    if ($fontMissing) {
      Write-Host ""
      Write-Host "   💡 After installing, set terminal font to: " -NoNewline -ForegroundColor DarkGray
      Write-Host "MonaspiceKr Nerd Font" -ForegroundColor Cyan
      Write-Host "      (Terminal → Settings → Text → Change Font)" -ForegroundColor DarkGray
    }
    
    # Show suppression hint
    Write-Host "   💡 To suppress warnings: " -NoNewline -ForegroundColor DarkGray
    Write-Host "profile ignore-dep <name>" -ForegroundColor Cyan
  }
}

# Run dependency check at startup
Test-Dependencies
