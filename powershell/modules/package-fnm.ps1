# ================================================================
# FNM (Fast Node Manager) SHORTCUTS
# ================================================================
# fnm shortcuts following same pattern as git (g), copilot (c), docker (d)
# Usage:
#   fn            → fnm list
#   fn u          → fnm use --install-if-missing
#   fn i 20       → fnm install 20
# ================================================================

<#
.SYNOPSIS
    fnm (Fast Node Manager) command shortcuts
.DESCRIPTION
    Quick aliases for fnm commands using single letters.
    Alias: fn
.PARAMETER Command
    Short command:
      u    = use --install-if-missing
      i    = install [version]
      il   = install --lts
      l    = list
      lr   = list-remote --lts
      ll   = list-remote --lts --latest
.PARAMETER Parameters
    Additional parameters passed to fnm command
.EXAMPLE
    fn               # fnm list
    fn u             # fnm use --install-if-missing
    fn i 20          # fnm install 20
    fn il            # fnm install --lts
    fn l             # fnm list
    fn lr            # fnm list-remote --lts
    fn ll            # fnm list-remote --lts --latest
.ALIAS
    fn
#>
function Invoke-Fnm {
  [Alias('fn')]
  Param(
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$Command,
    [Parameter(Mandatory = $false, ValueFromRemainingArguments = $true)]
    [string[]]$Parameters
  )

  # If no command, show installed versions
  if (-not $Command) {
    fnm list
    return
  }

  $normalizedCommand = switch ($Command) {
    'h'  { 'help' }
    default
     { $Command }
  }
  switch ($normalizedCommand) {
    'help' { Show-FnmHelp }
    'u'  { 
      # Check if a version file exists in the current directory
      $hasNvmrc = Test-Path ".nvmrc"
      $hasNodeVersion = Test-Path ".node-version"
      
      if (-not $hasNvmrc -and -not $hasNodeVersion) {
        Write-Host "⚠️  No .nvmrc or .node-version file found in this directory." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Tip: Create a version file to pin Node.js version for this project:" -ForegroundColor Cyan
        Write-Host "  echo '20' > .nvmrc                  # Pin to Node 20.x" -ForegroundColor Gray
        Write-Host "  echo '18.16.0' > .nvmrc             # Pin to exact version" -ForegroundColor Gray
        Write-Host "  echo 'lts/*' > .nvmrc               # Use latest LTS" -ForegroundColor Gray
        Write-Host ""
      }
      
      fnm use --install-if-missing $Parameters 
    }
    'i'  { fnm install $Parameters }
    'il' { fnm install --lts $Parameters }
    'l'  { fnm list $Parameters }
    'lr' { fnm list-remote --lts $Parameters }
    'll' { fnm list-remote --lts --latest $Parameters }
    default { fnm $Command $Parameters }
  }
}

# ================================================================
# HELP FUNCTION
# ================================================================

function Show-FnmHelp {
  Write-Host "  FNM SHORTCUTS (fn)" -ForegroundColor Green
  Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
  Write-Host "  Get Help: help fnm  OR  fn help  OR  fn h" -ForegroundColor Gray
  Write-Host ""
  Write-Host "📦 FNM (FAST NODE MANAGER)" -ForegroundColor Yellow
  Write-Host "   fn <cmd>                 fnm shortcuts:"
  Write-Host "     (none) = list          List installed node versions"
  Write-Host "     u      = use --auto    Use node version (auto-install if missing)"
  Write-Host "     i      = install [ver] Install specific version"
  Write-Host "     il     = install --lts Install latest LTS"
  Write-Host "     l      = list          List installed versions"
  Write-Host "     lr     = list-remote --lts      Show available LTS versions"
  Write-Host "     ll     = list-remote --lts --latest  Show latest LTS only"
  Write-Host ""
  Write-Host "💡 EXAMPLES" -ForegroundColor Yellow
  Write-Host "   fn                       List installed node versions"
  Write-Host "   fn u                     Use node version (auto-install if missing)"
  Write-Host "   fn i 20                  Install node 20"
  Write-Host "   fn il                    Install latest LTS"
  Write-Host "   fn lr                    Show all available LTS versions"
  Write-Host ""
}
