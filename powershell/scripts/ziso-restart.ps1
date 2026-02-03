#!/usr/bin/env pwsh
# Standalone script to restart ZoomISO (for remote execution)
# Returns exit code: 0 = success, 1 = failed
# Usage: pwsh -NoProfile /Users/lynbh/.config/powershell/scripts/ziso-restart.ps1

# Load the zoomiso module directly (no profile)
$moduleScript = Join-Path $PSScriptRoot "../modules/zoomiso.ps1"
. $moduleScript

# Call the function
Invoke-Zoomiso -Command restart

# Check final status and return exit code
$checkProcess = pgrep -i "zoomiso" 2>$null
if ($checkProcess) {
  exit 0  # Success - ZoomISO is running after restart
} else {
  exit 1  # Failed - ZoomISO not running after restart
}
