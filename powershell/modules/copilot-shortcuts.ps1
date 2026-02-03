# ================================================================
# COPILOT SHORTCUTS
# ================================================================
# Quick shortcuts for GitHub Copilot CLI
# ================================================================

<#
.SYNOPSIS
    Shortcut wrapper for GitHub Copilot CLI
.DESCRIPTION
    Provides short aliases for common Copilot CLI commands
.PARAMETER Command
    Short command: h (help),c (continue), cy (continue-yolo), r (resume), ry (resume-yolo), y (yolo)
.PARAMETER Parameters
    Additional parameters to pass to copilot
.EXAMPLE
    c y "create a function"  # Run with --yolo
    c c                      # Continue previous session
.ALIAS
    c
#>
function Invoke-Copilot {
  [Alias('c')]
  Param(
    [Parameter(Mandatory = $false, Position = 0)]
    [Alias("cmd")]
    [String]
    $Command,
    [Parameter(Mandatory = $false, ValueFromRemainingArguments = $true)]
    [Alias("params")]
    [String[]]
    $Parameters
  )

  # Normalize short aliases to full names
  $normalizedCommand = switch ($Command) {
    'h'  { 'help' }
    default { $Command }
  }

  Switch ($normalizedCommand) {
    # help
    'help' { Show-CopilotHelp }
    # continue
    'c' { copilot --continue $Parameters }
    # continue with yolo
    'cy' { copilot --continue --yolo $Parameters }
    # resume
    'r' { copilot --resume $Parameters }
    # resume with yolo
    'ry' { copilot --resume --yolo $Parameters }
    # yolo
    'y' { copilot --yolo $Parameters }
    # catchall
    default { copilot $Parameters }
  }
}



# ================================================================
# HELP FUNCTION
# ================================================================

function Show-CopilotHelp {
  Write-Host "  COPILOT CLI SHORTCUTS (c)" -ForegroundColor Green
  Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
  Write-Host "  Get Help: help copilot  OR  c help  OR  c h" -ForegroundColor Gray
  Write-Host ""
  Write-Host "🤖 COPILOT COMMANDS" -ForegroundColor Yellow
  Write-Host "   c <cmd>                  GitHub Copilot CLI shortcuts:"
  Write-Host "     (none)   = default       Run copilot normally"
  Write-Host "     help (h) = help          Show this help message"  
  Write-Host "     y        = --yolo        Auto-approve all suggestions"
  Write-Host "     c        = --continue    Continue previous session"
  Write-Host "     cy       = continue+yolo Continue with auto-approve"
  Write-Host "     r        = --resume      Resume session"
  Write-Host "     ry       = resume+yolo   Resume with auto-approve"
  Write-Host ""
  Write-Host "💡 EXAMPLES" -ForegroundColor Yellow
  Write-Host "   c 'create a function'    Normal copilot"
  Write-Host "   c y 'add tests'          Auto-approve all"
  Write-Host "   c c                      Continue previous"
  Write-Host "   c cy                     Continue with auto-approve"
  Write-Host ""
}
