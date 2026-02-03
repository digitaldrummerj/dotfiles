# ================================================================
# ZOOMISO PRODUCTION CONTROL
# ================================================================
# Quick commands for starting, stopping, and managing ZoomISO
# for production workflows when switching between meetings.
# ================================================================

<#
.SYNOPSIS
    ZoomISO application control
.DESCRIPTION
    Quick commands to start, stop, restart, and check ZoomISO status.
    Useful for production workflows when switching between meetings.
    Alias: ziso
.PARAMETER Command
    Short command:
      stop    = quit ZoomISO gracefully (like GUI quit)
      start   = launch ZoomISO
      restart = stop, wait, then start
      status  = check if ZoomISO is running
.EXAMPLE
    ziso stop      # Quit ZoomISO gracefully
    ziso start     # Start ZoomISO
    ziso restart   # Stop and start
    ziso status    # Check if running
.ALIAS
    ziso
#>
function Invoke-Zoomiso {
  [Alias('ziso')]
  Param(
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$Command = 'help'
  )

  $appName = "ZoomISO - v2"
  $normalizedCommand = switch ($Command) {
    'h'  { 'help' }
    default
     { $Command }
  }
  switch ($normalizedCommand) {
    'stop' {
      Write-Host "Stopping ZoomISO..." -ForegroundColor Yellow
      
      # Check if running first
      $running = pgrep -i "zoomiso" 2>$null
      if (-not $running) {
        Write-Host "ZoomISO is not running" -ForegroundColor Gray
        return
      }

      # Graceful quit using osascript (same as GUI File → Quit)
      osascript -e "quit app `"$appName`"" 2>$null
      
      if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to send quit command to ZoomISO" -ForegroundColor Red
        return
      }

      # Wait up to 60 seconds for process to stop
      $maxWaitSeconds = 60
      $waited = 0
      $stillRunning = $true
      
      Write-Host "Waiting for shutdown..." -ForegroundColor Gray
      while ($waited -lt $maxWaitSeconds) {
        Start-Sleep -Seconds 1
        $waited++
        
        $checkProcess = pgrep -i "zoomiso" 2>$null
        if (-not $checkProcess) {
          $stillRunning = $false
          break
        }
        
        # Show progress every second
        Write-Host "  Checking... ($waited seconds)" -ForegroundColor Gray
      }
      
      if (-not $stillRunning) {
        Write-Host "✅ ZoomISO stopped successfully (took $waited seconds)" -ForegroundColor Green
      } else {
        Write-Host "❌ ZoomISO did not stop after $maxWaitSeconds seconds" -ForegroundColor Red
        Write-Host "   Process may be hung. Consider force quitting from Activity Monitor." -ForegroundColor Yellow
      }
    }
    'start' {
      Write-Host "Starting ZoomISO..." -ForegroundColor Yellow
      
      # Check if already running
      $running = pgrep -i "zoomiso" 2>$null
      if ($running) {
        Write-Host "ZoomISO is already running (PID: $running)" -ForegroundColor Gray
        return
      }

      # Start the app
      open -a "$appName" 2>$null
      
      if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to start ZoomISO" -ForegroundColor Red
        Write-Host "   Make sure '$appName' is installed in /Applications" -ForegroundColor Gray
        return
      }

      # Wait up to 60 seconds for it to start
      $maxWaitSeconds = 60
      $waited = 0
      $started = $false
      
      Write-Host "Waiting for startup..." -ForegroundColor Gray
      while ($waited -lt $maxWaitSeconds) {
        Start-Sleep -Seconds 1
        $waited++
        
        $newProcessPid = pgrep -i "zoomiso" 2>$null
        if ($newProcessPid) {
          Write-Host "✅ ZoomISO started (PID: $newProcessPid, took $waited seconds)" -ForegroundColor Green
          $started = $true
          break
        }
        
        # Show progress every second
        Write-Host "  Checking... ($waited seconds)" -ForegroundColor Gray
      }
      
      if (-not $started) {
        Write-Host "⚠️  ZoomISO may not have started after $maxWaitSeconds seconds" -ForegroundColor Yellow
      }
    }
    'restart' {
      Write-Host "Restarting ZoomISO..." -ForegroundColor Cyan
      
      # Stop first
      Invoke-Zoomiso -Command stop
      
      # Wait a moment for clean shutdown
      Write-Host "Waiting for clean shutdown..." -ForegroundColor Gray
      Start-Sleep -Seconds 2
      
      # Start again
      Invoke-Zoomiso -Command start
    }
    'status' {
      $processPid = pgrep -i "zoomiso" 2>$null
      
      if ($processPid) {
        Write-Host "✅ ZoomISO is running (PID: $processPid)" -ForegroundColor Green
        
        # Show additional info
        $processInfo = ps -p $processPid -o pid,vsz,rss,%cpu,%mem,etime,command 2>$null | Select-Object -Skip 1
        if ($processInfo) {
          Write-Host "Process info:" -ForegroundColor Cyan
          Write-Host $processInfo -ForegroundColor Gray
        }
      } else {
        Write-Host "❌ ZoomISO is not running" -ForegroundColor Red
      }
    }
    'help' {
     Write-Host "  ZOOMISO SHORTCUTS (ziso)" -ForegroundColor Green
     Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
     Write-Host "  Get Help: help zoomiso  OR  ziso help  OR  ziso h" -ForegroundColor Gray
     Write-Host ""
      Write-Host "ziso <command>:" -ForegroundColor Yellow
      Write-Host "  stop      Quit ZoomISO gracefully" -ForegroundColor Gray
      Write-Host "  start     Launch ZoomISO" -ForegroundColor Gray
      Write-Host "  restart   Stop and start ZoomISO" -ForegroundColor Gray
      Write-Host "  status    Check if ZoomISO is running" -ForegroundColor Gray
      Write-Host ""
      Write-Host "Examples:" -ForegroundColor Yellow
      Write-Host "  ziso stop" -ForegroundColor Gray
      Write-Host "  ziso start" -ForegroundColor Gray
      Write-Host "  ziso restart" -ForegroundColor Gray
    }
    default {
      Write-Host "Usage: ziso <command>" -ForegroundColor Yellow
      Write-Host ""
      Write-Host "Commands:" -ForegroundColor Cyan
      Write-Host "  stop      Quit ZoomISO gracefully" -ForegroundColor Gray
      Write-Host "  start     Launch ZoomISO" -ForegroundColor Gray
      Write-Host "  restart   Stop and start ZoomISO" -ForegroundColor Gray
      Write-Host "  status    Check if ZoomISO is running" -ForegroundColor Gray
      Write-Host ""
      Write-Host "Examples:" -ForegroundColor Cyan
      Write-Host "  ziso stop" -ForegroundColor Gray
      Write-Host "  ziso start" -ForegroundColor Gray
      Write-Host "  ziso restart" -ForegroundColor Gray
    }
  }
}




# ================================================================
# HELP FUNCTION
# ================================================================

function Show-ZoomISOHelp {
  # Call the built-in ziso help
  ziso help
}
