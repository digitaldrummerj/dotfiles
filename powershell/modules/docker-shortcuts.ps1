# ================================================================
# DOCKER SHORTCUTS
# ================================================================

<#
.SYNOPSIS
    Docker command shortcuts
.DESCRIPTION
    Quick aliases for common docker commands using single letters.
    Alias: d
.PARAMETER Command
    Short command:
      start = Start Docker Desktop app
      b     = build       i    = images      l   = logs       p   = push
      c     = container   cs   = start       lf  = logs -f    v   = volume
      cx    = stop        k    = kill        li  = login      ps  = ps
      t     = tag         lo   = logout      r   = run        psf = formatted ps
.PARAMETER Parameters
    Additional parameters passed to docker command
.EXAMPLE
    d start           # Start Docker Desktop
    d ps              # docker ps
    d psf             # docker ps formatted (names, status, ports)
    d i               # docker images
    d l mycontainer   # docker logs mycontainer
    d lf mycontainer  # docker logs -f mycontainer (follow)
    d cs mycontainer  # docker container start mycontainer
.ALIAS
    d
#>
function Invoke-Docker {
  [Alias('d')]
  Param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Command,
    [Parameter(Mandatory = $false, ValueFromRemainingArguments = $true)]
    [string[]]$Parameters
  )

  $normalizedCommand = switch ($Command) {
    'h'  { 'help' }
    's'  { 'start' }
    default
     { $Command }
  }
  
  switch ($normalizedCommand) {
    'help' { Show-DockerHelp }
    'start' { 
      Write-Host "🐳 Starting Docker Desktop..." -ForegroundColor Cyan
      & open -a Docker
      Write-Host "✅ Docker Desktop launched" -ForegroundColor Green
    }
    'b' { docker build $Parameters }
    'c' { docker container $Parameters }
    'cs' { docker container start $Parameters }
    'cx' { docker container stop $Parameters }
    'i' { docker images $Parameters }
    't' { docker tag $Parameters }
    'k' { docker kill $Parameters }
    'l' { docker logs $Parameters }
    'lf' { docker logs -f $Parameters }
    'li' { docker login $Parameters }
    'lo' { docker logout $Parameters }
    'r' { docker run $Parameters }
    'p' { docker push $Parameters }
    'v' { docker volume $Parameters }
    'ps' { docker ps $Parameters }
    'psf' { docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" }
    default { docker $Command $Parameters }
  }
}

# ================================================================
# HELP FUNCTION
# ================================================================

function Show-DockerHelp {
  Write-Host "  DOCKER SHORTCUTS (d)" -ForegroundColor Green
  Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
  Write-Host "  Get Help: help docker  OR  d help  OR  d h" -ForegroundColor Gray
  Write-Host ""
  Write-Host "🐳 DOCKER COMMANDS" -ForegroundColor Yellow
  Write-Host "   d <cmd>                  Docker command shortcuts:"
  Write-Host "     start = Launch Docker Desktop"
  Write-Host "     b   = build          c   = container      cs  = start container"
  Write-Host "     cx  = stop container i   = images         k   = kill"
  Write-Host "     l   = logs           lf  = logs -f        li  = login"
  Write-Host "     lo  = logout         p   = push           ps  = ps"
  Write-Host "     psf = ps (formatted) r   = run            t   = tag"
  Write-Host "     v   = volume"
  Write-Host ""
  Write-Host "💡 EXAMPLES" -ForegroundColor Yellow
  Write-Host "   d start                  Launch Docker Desktop"
  Write-Host "   d ps                     Show running containers"
  Write-Host "   d psf                    Formatted container list"
  Write-Host "   d l mycontainer          Show logs for container"
  Write-Host "   d lf mycontainer         Follow logs (stream)"
  Write-Host ""
}
