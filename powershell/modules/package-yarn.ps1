# ================================================================
# YARN SHORTCUTS
# ================================================================
# Quick shortcuts for yarn commands
# Usage:
#   y             → yarn (install)
#   y d           → yarn dev
#   y r start     → yarn run start
# ================================================================

<#
.SYNOPSIS
    yarn command shortcuts
.DESCRIPTION
    Quick aliases for yarn commands using single letters.
    Alias: y
.PARAMETER Command
    Short command:
      (default) = yarn (install)
      i    = install       r    = run [script]    ui   = upgrade-interactive
      d    = run dev       s    = start
      b    = run build     t    = run test
.PARAMETER Parameters
    Additional parameters passed to yarn command
.EXAMPLE
    y                # yarn (install)
    y d              # yarn dev
    y r start:local  # yarn run start:local
    y ui             # yarn upgrade-interactive (check outdated packages)
    y r build --prod # yarn run build --prod
.ALIAS
    y
#>
function Invoke-Yarn {
  [Alias('y')]
  Param(
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$Command,
    [Parameter(Mandatory = $false, ValueFromRemainingArguments = $true)]
    [string[]]$Parameters
  )

  # If no command provided, just run yarn (install)
  if (-not $Command) {
    yarn
    return
  }

  $normalizedCommand = switch ($Command) {
    'h'  { 'help' }
    default
     { $Command }
  }
  switch ($normalizedCommand) {
    'help' { Show-YarnHelp }
    'i'  { yarn install $Parameters }
    'd'  { yarn dev $Parameters }
    'b'  { yarn build $Parameters }
    't'  { yarn test $Parameters }
    's'  { yarn start $Parameters }
    'r'  { yarn run $Parameters }
    'ui' { yarn upgrade-interactive $Parameters }
    default { yarn $Command $Parameters }
  }
}




# ================================================================
# HELP FUNCTION
# ================================================================

function Show-YarnHelp {
  Write-Host "  YARN SHORTCUTS (y)" -ForegroundColor Green
  Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
  Write-Host "  Get Help: help yarn  OR  y help  OR  y h" -ForegroundColor Gray
  Write-Host ""
  Write-Host "📦 YARN COMMANDS" -ForegroundColor Yellow
  Write-Host "   y <cmd>                  yarn command shortcuts:"
  Write-Host "     (none) = install     i  = install        d  = run dev"
  Write-Host "     b      = run build   t  = run test       s  = start"
  Write-Host "     r      = run [script]                    ui = upgrade-interactive"
  Write-Host ""
  Write-Host "💡 EXAMPLES" -ForegroundColor Yellow
  Write-Host "   y                        yarn (install)"
  Write-Host "   y d                      yarn dev"
  Write-Host "   y r start:local          yarn run start:local"
  Write-Host "   y ui                     yarn upgrade-interactive"
  Write-Host ""
}
