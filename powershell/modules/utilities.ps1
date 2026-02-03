# ================================================================
# UTILITY FUNCTIONS
# ================================================================

<#
.SYNOPSIS
    Quick Fahrenheit to Celsius conversion
.DESCRIPTION
    Converts Fahrenheit temperature to Celsius using simplified formula
.EXAMPLE
    2C 72  # Returns approximately 21°C
#>
function 2C {
  param (
      [Parameter()]
      [Alias('Temp')]
      [int]
      $Temperature
  )

  ($Temperature - 30) / 2
}

<#
.SYNOPSIS
    Quick Celsius to Fahrenheit conversion
.DESCRIPTION
    Converts Celsius temperature to Fahrenheit using simplified formula
.EXAMPLE
    2F 20  # Returns approximately 68°F
#>
function 2F {
  param (
      [Parameter()]
      [Alias('Temp')]
      [int]
      $Temperature
  )

  ($Temperature * 2) + 30
}

<#
.SYNOPSIS
    Update Homebrew and PowerShell
.DESCRIPTION
    Runs brew update and upgrades PowerShell to the latest version
.EXAMPLE
    update
#>
function update {
    brew update
    brew upgrade powershell
}

<#
.SYNOPSIS
    Set environment variable securely in macOS Keychain
.DESCRIPTION
    Sets an environment variable for the current session AND stores it
    securely in macOS Keychain so it persists across terminal sessions.
    Secrets are stored with prefix 'pwsh-env-' in Keychain.
.PARAMETER Name
    Environment variable name (e.g., 'GITHUB_GIST_TOKEN')
.PARAMETER Value
    Value to set (will be stored securely)
.EXAMPLE
    SetEnv 'GITHUB_GIST_TOKEN' 'ghp_xxxxxxxxxxxx'
.NOTES
    Profile startup automatically loads variables from Keychain.
    View/edit keychain entries in Keychain Access.app
#>
function SetEnv {
  param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Name,
    [Parameter(Mandatory = $true, Position = 1)]
    [string]$Value
  )

  # Set for current session
  [System.Environment]::SetEnvironmentVariable($Name, $Value, [System.EnvironmentVariableTarget]::Process)
  
  # Store in macOS Keychain for persistence across sessions
  try {
    # Try to update existing entry first (-U flag)
    & security add-generic-password -a "$env:USER" -s "pwsh-env-$Name" -w $Value -U 2>$null
    if ($LASTEXITCODE -ne 0) {
      # If update fails, add new entry
      & security add-generic-password -a "$env:USER" -s "pwsh-env-$Name" -w $Value
    }
    Write-Host "Environment variable '$Name' set and stored securely in macOS Keychain." -ForegroundColor Green
  }
  catch {
    Write-Error "Failed to store '$Name' in Keychain: $_"
  }
}

# ================================================================
# POWER USER FEATURES
# ================================================================
# Advanced shortcuts and developer tools:
# - Docker & Docker Compose shortcuts (d, dc)
# - JSON pretty-printing (jj)
# - Performance timing (perf)
# - System info (ports, disk)
# ================================================================

<#
.SYNOPSIS
    Pretty-print JSON with syntax highlighting
.DESCRIPTION
    Formats JSON for easy reading. Accepts piped input.
    Alias: jj
.PARAMETER InputObject
    JSON string to format (accepts pipeline input)
.EXAMPLE
    '{"name":"test","value":123}' | jj
    Get-Content data.json | jj
    curl https://api.example.com/data | jj
.ALIAS
    jj
#>
function Show-Json {
  [Alias('jj')]
  Param(
    [Parameter(ValueFromPipeline = $true)]
    [string]$InputObject
  )
  
  process {
    if ($InputObject) {
      $InputObject | ConvertFrom-Json | ConvertTo-Json -Depth 10 | Out-Host
    }
  }
}

# System info shortcuts
function Get-ListeningPorts {
  [Alias('ports')]
  Param()
  
  Write-Host "Listening ports:" -ForegroundColor Green
  lsof -iTCP -sTCP:LISTEN -n -P | Select-Object -Skip 1
}





# ================================================================
# HELP FUNCTION
# ================================================================

function Show-UtilitiesHelp {
  Write-Host "  UTILITIES" -ForegroundColor Green
  Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
  Write-Host "  Get Help: help utilities" -ForegroundColor Gray
  Write-Host ""
  Write-Host "  Aliases: utilities, util" -ForegroundColor Gray
  Write-Host ""
  Write-Host "🛠️  UTILITY COMMANDS" -ForegroundColor Yellow
  Write-Host "   2C <temp>                Convert Fahrenheit to Celsius"
  Write-Host "   2F <temp>                Convert Celsius to Fahrenheit"
  Write-Host "   update                   Update Homebrew & PowerShell"
  Write-Host "   SetEnv 'NAME' 'value'    Store env var in Keychain (persists)"
  Write-Host "   jj <json>                Pretty-print JSON"
  Write-Host "   ports                    Show listening ports"
  Write-Host ""
  Write-Host "💡 EXAMPLES" -ForegroundColor Yellow
  Write-Host "   2C 72                    Convert 72°F to Celsius"
  Write-Host "   2F 20                    Convert 20°C to Fahrenheit"
  Write-Host "   SetEnv 'API_KEY' 'abc'   Store API key securely"
  Write-Host "   jj '{\"a\":1}'           Pretty-print JSON"
  Write-Host ""
}
