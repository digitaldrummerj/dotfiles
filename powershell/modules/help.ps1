# ================================================================
# HELP & STARTUP BANNER
# ================================================================

<#
.SYNOPSIS
    Display comprehensive help for all profile features or specific topics
.DESCRIPTION
    Shows all available shortcuts, tools, and features organized by category.
    Can display help for specific topics or all topics.
.PARAMETER Topic
    Optional topic to show help for. Available topics:
    g, git, fn, fnm, n, npm, y, yarn, d, docker, dc, ob, obvio, bk, bookmark, profile, ziso, comp, companion
.EXAMPLE
    Show-ProfileHelp
    help
    Show all available help topics
.EXAMPLE
    help g
    Show only git shortcuts
.EXAMPLE
    help ob
    Show only obvio project management commands
.ALIAS
    help
#>
function Show-ProfileHelp {
  [Alias('help')]
  param(
    [Parameter(Position=0)]
    [ValidateSet('', 'g', 'git', 'fn', 'fnm', 'n', 'npm', 'y', 'yarn', 'd', 'docker', 'dc', 'docker-compose', 'c', 'copilot', 'ob', 'obvio', 'bk', 'bookmark', 'profile', 'ziso', 'cm', 'comp', 'companion', 'util', 'utilities')]
    [string]$Topic = ''
  )
  
  # Normalize aliases to canonical names
  $topicMap = @{
    'g'              = 'git'
    'fn'             = 'fnm'
    'n'              = 'npm'
    'y'              = 'yarn'
    'd'              = 'docker'
    'dc'             = 'docker-compose'
    'c'              = 'copilot'
    'ob'             = 'obvio'
    'bk'             = 'bookmark'
    'cm'             = 'companion'
    'comp'           = 'companion'
    'util'           = 'utilities'
    'u'              = 'utilities'
  }
  
  if ($topicMap.ContainsKey($Topic)) {
    $Topic = $topicMap[$Topic]
  }
  
  # If no topic specified, show topic list
  if (-not $Topic) {
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  POWERSHELL PROFILE - QUICK REFERENCE" -ForegroundColor Green
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📖 AVAILABLE HELP TOPICS" -ForegroundColor Yellow
    Write-Host "   Type 'help <topic>' for detailed information on:"
    Write-Host ""
    Write-Host "   git (g)              Git shortcuts and workflows"
    Write-Host "   fnm (fn)             Fast Node Manager shortcuts"
    Write-Host "   npm (n)              npm command shortcuts"
    Write-Host "   yarn (y)             yarn command shortcuts"
    Write-Host "   docker (d)           Docker command shortcuts"
    Write-Host "   docker-compose (dc)  Docker Compose shortcuts"
    Write-Host "   copilot (c)          GitHub Copilot CLI shortcuts"
    Write-Host "   obvio (ob)           Obvio project management"
    Write-Host "   bookmark (bk)        Directory bookmarks"
    Write-Host "   companion (comp)     Companion module navigation"
    Write-Host "   profile              Profile management commands"
    Write-Host "   ziso                 ZoomISO production control"
    Write-Host "   utilities (util)     Utility functions (temp, SetEnv, JSON, etc.)"
    Write-Host ""
    Write-Host "💡 EXAMPLES" -ForegroundColor Yellow
    Write-Host "   help git             Show all git shortcuts"
    Write-Host "   help ob              Show obvio commands"
    Write-Host "   help n               Show npm shortcuts"
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    return
  }
  
  # Show topic-specific help
  Write-Host ""
  Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
  
  switch ($Topic) {
    'git' {
      Show-GitHelp
    }
    'fnm' {
      Show-FnmHelp
    }
    'npm' {
      Show-NpmHelp
    }
    'yarn' {
      Show-YarnHelp
    }
    'docker' {
      Show-DockerHelp
    }
    'docker-compose' {
      Show-DockerComposeHelp
    }
    'copilot' {
      Show-CopilotHelp
    }
    'obvio' {
      Show-ObvioHelp
    }
    'bookmark' {
      Show-BookmarkHelp
    }
    'companion' {
      Show-CompanionHelp
    }
    'profile' {
      Show-ProfileSyncHelp
    }
    'ziso' {
      Show-ZoomISOHelp
    }
    'utilities' {
      Show-UtilitiesHelp
    }
  }
  
  Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
  Write-Host ""
}
