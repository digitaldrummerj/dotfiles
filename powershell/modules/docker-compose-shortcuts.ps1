# ================================================================
# DOCKER COMPOSE SHORTCUTS
# ================================================================

<#
.SYNOPSIS
    Docker Compose command shortcuts
.DESCRIPTION
    Quick aliases for docker-compose commands. Perfect for Obvio projects.
    Alias: dc
.PARAMETER Command
    Short command:
      b   = build       l   = logs        u   = up
      c   = create      s   = start       ud  = up --detach
      d   = down        x   = stop        rmi = images
.PARAMETER Parameters
    Additional parameters passed to docker-compose command
.EXAMPLE
    dc u              # docker-compose up
    dc ud             # docker-compose up --detach (background)
    dc d              # docker-compose down
    dc l              # docker-compose logs
    dc l -f myservice # docker-compose logs -f myservice
.ALIAS
    dc
#>
function Invoke-DockerCompose {
  [Alias('dc')]
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
    'help' { Show-DockerComposeHelp }
    'b' { docker-compose build $Parameters }
    'c' { docker-compose create $Parameters }
    'd' { docker-compose down $Parameters }
    'l' { docker-compose logs $Parameters }
    's' { docker-compose start $Parameters }
    'u' { docker-compose up $Parameters }
    'ud' { docker-compose up --detach $Parameters }
    'x' { docker-compose stop $Parameters }
    'rmi' { docker-compose images }
    default { docker-compose $Command $Parameters }
  }
}

# ================================================================
# HELP FUNCTION
# ================================================================

function Show-DockerComposeHelp {
  Write-Host "  DOCKER COMPOSE SHORTCUTS (dc)" -ForegroundColor Green
  Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
  Write-Host "  Get Help: help docker-compose  OR  dc help  OR  dc h" -ForegroundColor Gray
  Write-Host ""
  Write-Host "🐳 DOCKER COMPOSE COMMANDS" -ForegroundColor Yellow
  Write-Host "   dc <cmd>                 Docker Compose shortcuts:"
  Write-Host "     b   = build          c   = create         d   = down"
  Write-Host "     l   = logs           s   = start          u   = up"
  Write-Host "     ud  = up --detach    x   = stop           rmi = images"
  Write-Host ""
  Write-Host "💡 EXAMPLES" -ForegroundColor Yellow
  Write-Host "   dc u                     Start all services (foreground)"
  Write-Host "   dc ud                    Start all services (background)"
  Write-Host "   dc d                     Stop and remove containers"
  Write-Host "   dc l -f myservice        Follow logs for one service"
  Write-Host ""
}
