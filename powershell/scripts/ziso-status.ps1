#!/usr/bin/env pwsh
# Standalone script to check ZoomISO status (for remote execution)
# Returns exit code: 0 = running, 1 = not running
# Usage: pwsh -NoProfile /Users/lynbh/.config/powershell/scripts/ziso-status.ps1

# Load the zoomiso module directly (no profile)
$moduleScript = Join-Path $PSScriptRoot "../modules/zoomiso.ps1"
. $moduleScript

# Call the function
Invoke-Zoomiso -Command status

# Return appropriate exit code
$checkProcess = pgrep -i "zoomiso" 2>$null
if ($checkProcess) {
  exit 0  # Running
} else {
  exit 1  # Not running
}
