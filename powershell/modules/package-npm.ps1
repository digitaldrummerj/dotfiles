# ================================================================
# NPM SHORTCUTS
# ================================================================
# Quick shortcuts for npm commands
# Usage:
#   n i           → npm install
#   n d           → npm run dev
#   n r build     → npm run build
# ================================================================

<#
.SYNOPSIS
    npm command shortcuts
.DESCRIPTION
    Quick aliases for npm commands using single letters.
    Alias: n
.PARAMETER Command
    Short command:
      i    = install       r    = run [script]    o   = outdated
      ci   = ci (clean)    s    = start           u   = update
      d    = run dev       t    = run test
      b    = run build
.PARAMETER Parameters
    Additional parameters passed to npm command
.EXAMPLE
    n i              # npm install
    n d              # npm run dev
    n r build:prod   # npm run build:prod
    n r test --watch # npm run test --watch
.ALIAS
    n
#>
function Invoke-Npm {
  [Alias('n')]
  Param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Command,
    [Parameter(Mandatory = $false, ValueFromRemainingArguments = $true)]
    [string[]]$Parameters
  )

  $normalizedCommand = switch ($Command) {
    'h'  { 'help' }
    default
     { $Command }
  }

  switch ($normalizedCommand) {
    'help' { Show-NpmHelp }
    'i'  { npm install $Parameters }
    'ci' { npm ci $Parameters }
    'd'  { npm run dev $Parameters }
    'b'  { npm run build $Parameters }
    't'  { npm run test $Parameters }
    's'  { npm start $Parameters }
    'r'  { npm run $Parameters }
    'o'  { npm outdated $Parameters }
    'u'  { npm update $Parameters }
    default { npm $Command $Parameters }
  }
}




# ================================================================
# HELP FUNCTION
# ================================================================

function Show-NpmHelp {
  Write-Host "  NPM SHORTCUTS (n)" -ForegroundColor Green
  Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
  Write-Host "  Get Help: help npm  OR  n help  OR  n h" -ForegroundColor Gray
  Write-Host ""
  Write-Host "📦 NPM COMMANDS" -ForegroundColor Yellow
  Write-Host "   n <cmd>                  npm command shortcuts:"
  Write-Host "     i  = install         ci = ci (clean)      d = run dev"
  Write-Host "     b  = run build       t  = run test        s = start"
  Write-Host "     r  = run [script]    o  = outdated        u = update"
  Write-Host ""
  Write-Host "💡 EXAMPLES" -ForegroundColor Yellow
  Write-Host "   n i                      npm install"
  Write-Host "   n d                      npm run dev"
  Write-Host "   n r build:prod           npm run build:prod"
  Write-Host "   n r test --watch         npm run test --watch"
  Write-Host ""
}
