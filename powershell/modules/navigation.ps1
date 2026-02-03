# ================================================================
# FOLDER NAVIGATION & FINDER
# ================================================================

# Load bookmarks from config (supports both old flat format and new grouped format)
$script:Bookmarks = @{}
$script:BookmarksGlobal = @{}
$script:BookmarksLocal = @{}
$script:BookmarkFile = $script:bookmarksPath

if (Test-Path $script:BookmarkFile) {
  try {
    $bookmarkData = Get-Content $script:BookmarkFile -Raw | ConvertFrom-Json
    
    # Check if using old flat format or new grouped format
    if ($bookmarkData.PSObject.Properties['global'] -or $bookmarkData.PSObject.Properties['local']) {
      # New grouped format
      if ($bookmarkData.global) {
        $script:BookmarksGlobal = @{}
        foreach ($prop in $bookmarkData.global.PSObject.Properties) {
          $script:BookmarksGlobal[$prop.Name] = $prop.Value
        }
      }
      
      if ($bookmarkData.local -and $bookmarkData.local.PSObject.Properties[$script:machineName]) {
        $script:BookmarksLocal = @{}
        foreach ($prop in $bookmarkData.local.$($script:machineName).PSObject.Properties) {
          $script:BookmarksLocal[$prop.Name] = $prop.Value
        }
      }
    }
    else {
      # Old flat format - auto-migrate to new format
      Write-Host "📦 Migrating bookmarks to new format (local/global)..." -ForegroundColor Yellow
      
      # Convert old format to hashtable
      $script:BookmarksGlobal = @{}
      foreach ($prop in $bookmarkData.PSObject.Properties) {
        $script:BookmarksGlobal[$prop.Name] = $prop.Value
      }
      
      # Create new format structure
      $newFormat = @{
        global = $script:BookmarksGlobal
        local = @{}
      }
      
      # Save migrated format
      $newFormat | ConvertTo-Json -Depth 10 | Set-Content $script:BookmarkFile
      
      Write-Host "✅ Migration complete! All bookmarks are now global." -ForegroundColor Green
      Write-Host "   Use 'bk add <name> <path>' to add machine-specific bookmarks." -ForegroundColor Cyan
    }
    
    # Create merged view (local overrides global)
    $script:Bookmarks = $script:BookmarksGlobal.Clone()
    foreach ($key in $script:BookmarksLocal.Keys) {
      $script:Bookmarks[$key] = $script:BookmarksLocal[$key]
    }
  }
  catch {
    Write-Warning "Failed to load bookmarks: $_"
    $script:Bookmarks = @{}
    $script:BookmarksGlobal = @{}
    $script:BookmarksLocal = @{}
  }
}
else {
  # No bookmark file - create new format structure
  $newFormat = @{
    global = @{}
    local = @{}
  }
  $newFormat | ConvertTo-Json -Depth 10 | Set-Content $script:BookmarkFile
}

function Open-InFinder {
  <#
  .SYNOPSIS
    Opens a folder in macOS Finder
  .DESCRIPTION
    Opens the specified folder in Finder. Supports both paths and folder shortcuts (downloads, dev, movies, docs).
    If no path is provided, opens the current directory.
  .PARAMETER Path
    The path or folder shortcut to open in Finder. Defaults to current directory.
  .EXAMPLE
    f
    Opens current directory in Finder
  .EXAMPLE
    f downloads
    Opens Downloads folder in Finder using shortcut
  .EXAMPLE
    f ~/Desktop
    Opens Desktop folder in Finder using path
  .ALIAS
    finder, f
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$false, Position=0, ValueFromPipeline=$true)]
    [string]$Path = '.'
  )
  
  process {
    # Check if it's a bookmark
    if ($script:Bookmarks.ContainsKey($Path)) {
      $bookmarkPath = $script:Bookmarks[$Path]
      # Expand ~ to home directory
      $resolvedPath = $bookmarkPath -replace '^~', $HOME
    }
    # Resolve the path - use current location if just '.'
    elseif ($Path -eq '.') {
      $resolvedPath = Get-Location | Select-Object -ExpandProperty Path
    }
    else {
      try {
        $resolvedPath = Resolve-Path -Path $Path -ErrorAction Stop | Select-Object -ExpandProperty Path
      }
      catch {
        Write-Host "❗ Path not found: $Path" -ForegroundColor Red
        return
      }
    }
    
    # Verify path exists
    if (-not (Test-Path -LiteralPath $resolvedPath)) {
      Write-Host "❗ Folder not found: $resolvedPath" -ForegroundColor Red
      return
    }
    
    # Open in Finder
    Write-Host "📂 Opening in Finder: $resolvedPath" -ForegroundColor Cyan
    & open -a Finder $resolvedPath
  }
}

function Invoke-FolderNavigation {
  <#
  .SYNOPSIS
    Navigate to bookmarked folders or paths in the terminal
  .DESCRIPTION
    Quickly navigate to bookmarked folders or any valid path. Use 'bookmark list' to see all available bookmarks.
  .PARAMETER Folder
    The bookmark name or path to navigate to (supports .., ., relative paths, absolute paths)
  .EXAMPLE
    to downloads
    Navigate to Downloads folder using bookmark
  .EXAMPLE
    goto dev
    Navigate to Development folder using bookmark
  .EXAMPLE
    to ..
    Navigate to parent directory
  .EXAMPLE
    to ~/Desktop
    Navigate to Desktop using path
  .ALIAS
    to, goto
  #>
  param(
    [Parameter(Position=0, Mandatory=$true)]
    [string]$Folder
  )
  
  # Check if it's a bookmark first
  if ($script:Bookmarks.ContainsKey($Folder)) {
    $bookmarkPath = $script:Bookmarks[$Folder]
    # Expand ~ to home directory
    $targetPath = $bookmarkPath -replace '^~', $HOME
  }
  # Otherwise treat as a path
  else {
    try {
      $targetPath = Resolve-Path -Path $Folder -ErrorAction Stop | Select-Object -ExpandProperty Path
    }
    catch {
      Write-Host "❗ Path or bookmark not found: $Folder. Use 'bk list' to see available bookmarks." -ForegroundColor Red
      return
    }
  }
  
  if (-not (Test-Path -LiteralPath $targetPath)) {
    Write-Host "❗ Folder not found: $targetPath" -ForegroundColor Red
    return
  }
  
  Set-Location -LiteralPath $targetPath
  Write-Host "📁 Navigated to: $targetPath" -ForegroundColor Cyan
}

<#
.SYNOPSIS
    Directory bookmark system for instant navigation
.DESCRIPTION
    Save directories and jump to them with short names.
    Bookmarks persist across terminal sessions.
.PARAMETER Action
    Action to perform: add, remove, list, or bookmark name to jump to
.PARAMETER Name
    Bookmark name (required for add/remove)
.PARAMETER F
    Open bookmark location in Finder instead of navigating in terminal
.EXAMPLE
    # Save current location
    cd ~/Development/some/deep/path
    bookmark add proj
    
    # Later, jump back instantly in terminal
    bookmark proj
    
    # Or open in Finder
    bookmark proj -F
    
    # Manage bookmarks
    bookmark list           # Show all bookmarks
    bookmark remove proj    # Delete bookmark
.NOTES
    Bookmarks stored in: $bookmarksPath
    Use for any frequently-visited directories
    Complements fixed shortcuts like oea, oew and companion nav (cm n hdtv)
#>
function bookmark {
  [Alias('bk')]
  Param(
    [Parameter(Position = 0)]
    [string]$Action,
    [Parameter(Position = 1)]
    [string]$Name,
    [switch]$F,
    [switch]$Global,
    [switch]$Local,
    [switch]$All,
    [Parameter(ValueFromRemainingArguments)]
    [string]$Machine
  )
  
  switch ($Action) {

    'h' {
      Show-BookmarkHelp
    }
    'help' {
      Show-BookmarkHelp
    }
    'add' {
      if (-not $Name) {
        Write-Error "Usage: bookmark add <name> [-Global]"
        return
      }
      $currentPath = Get-Location | Select-Object -ExpandProperty Path
      # Replace home directory with ~ for portability
      if ($currentPath.StartsWith($HOME)) {
        $portablePath = $currentPath -replace [regex]::Escape($HOME), '~'
      } else {
        $portablePath = $currentPath
      }
      
      # Load current bookmark file
      $bookmarkData = Get-Content $script:BookmarkFile -Raw | ConvertFrom-Json
      
      if ($Global) {
        # Add to global section
        if (-not $bookmarkData.global) {
          $bookmarkData | Add-Member -MemberType NoteProperty -Name 'global' -Value (New-Object PSObject)
        }
        $bookmarkData.global | Add-Member -MemberType NoteProperty -Name $Name -Value $portablePath -Force
        $script:BookmarksGlobal[$Name] = $portablePath
        $script:Bookmarks[$Name] = $portablePath
        Write-Host "✅ Global bookmark '$Name' saved: $portablePath" -ForegroundColor Green
      }
      else {
        # Add to local section for this machine
        if (-not $bookmarkData.local) {
          $bookmarkData | Add-Member -MemberType NoteProperty -Name 'local' -Value (New-Object PSObject)
        }
        if (-not $bookmarkData.local.PSObject.Properties[$script:machineName]) {
          $bookmarkData.local | Add-Member -MemberType NoteProperty -Name $script:machineName -Value (New-Object PSObject)
        }
        $bookmarkData.local.$($script:machineName) | Add-Member -MemberType NoteProperty -Name $Name -Value $portablePath -Force
        $script:BookmarksLocal[$Name] = $portablePath
        $script:Bookmarks[$Name] = $portablePath
        Write-Host "✅ Local bookmark '$Name' saved: $portablePath" -ForegroundColor Green
        Write-Host "   Machine: $script:machineName" -ForegroundColor DarkGray
      }
      
      # Save to file
      $bookmarkData | ConvertTo-Json -Depth 10 | Set-Content $script:BookmarkFile
    }
    'remove' {
      if (-not $Name) {
        Write-Error "Usage: bookmark remove <name> [-Global]"
        return
      }
      
      # Load current bookmark file
      $bookmarkData = Get-Content $script:BookmarkFile -Raw | ConvertFrom-Json
      $removed = $false
      
      if ($Global) {
        # Remove from global only
        if ($bookmarkData.global.PSObject.Properties[$Name]) {
          $bookmarkData.global.PSObject.Properties.Remove($Name)
          $script:BookmarksGlobal.Remove($Name)
          $removed = $true
          Write-Host "✅ Global bookmark '$Name' removed" -ForegroundColor Green
        }
        else {
          Write-Host "❌ Bookmark '$Name' not found in global bookmarks" -ForegroundColor Yellow
          return
        }
      }
      else {
        # Try local first, then global
        if ($bookmarkData.local.PSObject.Properties[$script:machineName] -and 
            $bookmarkData.local.$($script:machineName).PSObject.Properties[$Name]) {
          $bookmarkData.local.$($script:machineName).PSObject.Properties.Remove($Name)
          $script:BookmarksLocal.Remove($Name)
          $removed = $true
          Write-Host "✅ Local bookmark '$Name' removed (machine: $script:machineName)" -ForegroundColor Green
        }
        elseif ($bookmarkData.global.PSObject.Properties[$Name]) {
          $bookmarkData.global.PSObject.Properties.Remove($Name)
          $script:BookmarksGlobal.Remove($Name)
          $removed = $true
          Write-Host "✅ Global bookmark '$Name' removed" -ForegroundColor Green
        }
        else {
          Write-Host "❌ Bookmark '$Name' not found" -ForegroundColor Yellow
          return
        }
      }
      
      if ($removed) {
        # Rebuild merged view
        $script:Bookmarks = $script:BookmarksGlobal.Clone()
        foreach ($key in $script:BookmarksLocal.Keys) {
          $script:Bookmarks[$key] = $script:BookmarksLocal[$key]
        }
        
        # Save to file
        $bookmarkData | ConvertTo-Json -Depth 10 | Set-Content $script:BookmarkFile
      }
    }
    'list' {
      if ($script:Bookmarks.Count -eq 0) {
        Write-Host "No bookmarks saved" -ForegroundColor Yellow
        return
      }
      
      if ($Local) {
        # Show only local bookmarks for this machine
        if ($script:BookmarksLocal.Count -eq 0) {
          Write-Host "No local bookmarks for this machine" -ForegroundColor Yellow
          return
        }
        Write-Host "`nLocal Bookmarks (machine: $script:machineName):" -ForegroundColor Green
        foreach ($key in $script:BookmarksLocal.Keys | Sort-Object) {
          Write-Host "  $key [L] -> $($script:BookmarksLocal[$key])"
        }
      }
      elseif ($Global) {
        # Show only global bookmarks
        if ($script:BookmarksGlobal.Count -eq 0) {
          Write-Host "No global bookmarks" -ForegroundColor Yellow
          return
        }
        Write-Host "`nGlobal Bookmarks:" -ForegroundColor Green
        foreach ($key in $script:BookmarksGlobal.Keys | Sort-Object) {
          Write-Host "  $key -> $($script:BookmarksGlobal[$key])"
        }
      }
      elseif ($All) {
        # Show all machines' bookmarks (debugging)
        $bookmarkData = Get-Content $script:BookmarkFile -Raw | ConvertFrom-Json
        
        Write-Host "`nGlobal Bookmarks:" -ForegroundColor Green
        if ($bookmarkData.global.PSObject.Properties.Count -gt 0) {
          foreach ($prop in $bookmarkData.global.PSObject.Properties | Sort-Object Name) {
            Write-Host "  $($prop.Name) -> $($prop.Value)"
          }
        }
        else {
          Write-Host "  (none)" -ForegroundColor DarkGray
        }
        
        Write-Host "`nLocal Bookmarks (all machines):" -ForegroundColor Green
        if ($bookmarkData.local.PSObject.Properties.Count -gt 0) {
          foreach ($machineProp in $bookmarkData.local.PSObject.Properties | Sort-Object Name) {
            Write-Host "  [$($machineProp.Name)]:" -ForegroundColor Cyan
            foreach ($bookmarkProp in $machineProp.Value.PSObject.Properties | Sort-Object Name) {
              Write-Host "    $($bookmarkProp.Name) -> $($bookmarkProp.Value)"
            }
          }
        }
        else {
          Write-Host "  (none)" -ForegroundColor DarkGray
        }
      }
      else {
        # Show merged view (default)
        Write-Host "`nBookmarks:" -ForegroundColor Green
        foreach ($key in $script:Bookmarks.Keys | Sort-Object) {
          $isLocal = $script:BookmarksLocal.ContainsKey($key)
          if ($isLocal) {
            Write-Host "  $key [L] -> $($script:Bookmarks[$key])"
          }
          else {
            Write-Host "  $key -> $($script:Bookmarks[$key])"
          }
        }
        Write-Host "`n  [L] = Local to this machine ($script:machineName)" -ForegroundColor DarkGray
      }
    }
    default {
      if ($script:Bookmarks.ContainsKey($Action)) {
        $bookmarkPath = $script:Bookmarks[$Action]
        # Expand ~ to home directory
        $path = $bookmarkPath -replace '^~', $HOME
        if ($F) {
          # Open in Finder
          Write-Host "📂 Opening in Finder: $path" -ForegroundColor Cyan
          & open -a Finder $path
        }
        else {
          # Navigate in terminal
          Set-Location $path
          Write-Host "📁 Navigated to: $path" -ForegroundColor Cyan
        }
      }
      else {
        Write-Host "Unknown bookmark: $Action" -ForegroundColor Yellow
        Write-Host "Usage: bookmark add|remove|list [name] [-Global]" -ForegroundColor Cyan
        Write-Host "   Or: bookmark <name> [-F] to jump to saved location" -ForegroundColor Cyan
      }
    }
  }
}

# Register tab completers for bookmark command
Register-ArgumentCompleter -CommandName 'bookmark' -ParameterName 'Action' -ScriptBlock {
  param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
  $actions = @('add', 'remove', 'list')
  $completions = $actions + $script:Bookmarks.Keys
  $completions | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
  }
}

Register-ArgumentCompleter -CommandName 'bookmark' -ParameterName 'Name' -ScriptBlock {
  param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
  if ($fakeBoundParameters['Action'] -eq 'remove') {
    $script:Bookmarks.Keys | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
      [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
  }
}

# Set aliases
Set-Alias -Name to -Value Invoke-FolderNavigation
Set-Alias -Name goto -Value Invoke-FolderNavigation
Set-Alias -Name cmd -Value Invoke-FolderNavigation
Set-Alias -Name finder -Value Open-InFinder
Set-Alias -Name f -Value Open-InFinder




# ================================================================
# HELP FUNCTION
# ================================================================

function Show-BookmarkHelp {
  Write-Host "  BOOKMARKS (bk)" -ForegroundColor Green
  Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
  Write-Host "  Get Help: help bookmark  OR  bk help  OR  bk h" -ForegroundColor Gray
  Write-Host "  Aliases: bookmark, bk" -ForegroundColor Gray
  Write-Host ""
  Write-Host "🔖 BOOKMARK COMMANDS" -ForegroundColor Yellow
  Write-Host "   bookmark (bk) add <name>           Save current directory (local to machine)"
  Write-Host "   bookmark (bk) add <name> -Global   Save as global bookmark (all machines)"
  Write-Host "   bookmark (bk) <name>               Jump to saved directory"
  Write-Host "   bookmark (bk) <name> -F            Open bookmark in Finder"
  Write-Host "   bookmark (bk) list                 Show all bookmarks (merged view)"
  Write-Host "   bookmark (bk) list -Local          Show only local bookmarks"
  Write-Host "   bookmark (bk) list -Global         Show only global bookmarks"
  Write-Host "   bookmark (bk) list -All            Show all machines' bookmarks"
  Write-Host "   bookmark (bk) remove <name>        Delete bookmark (local, then global)"
  Write-Host "   bookmark (bk) remove <name> -Global  Delete specifically from global"
  Write-Host ""
  Write-Host "💡 LOCAL VS GLOBAL" -ForegroundColor Yellow
  Write-Host "   Local bookmarks [L]  - Machine-specific paths, stored per hostname"
  Write-Host "   Global bookmarks     - Shared across all machines (downloads, docs, etc.)"
  Write-Host "   Machine name: $script:machineName" -ForegroundColor DarkGray
  Write-Host "   Override: SetEnv 'MACHINE_NAME' 'custom-name'" -ForegroundColor DarkGray
  Write-Host ""
  Write-Host "💡 EXAMPLES" -ForegroundColor Yellow
  Write-Host "   bk add myproject         Save current directory (local to this machine)"
  Write-Host "   bk add downloads -Global Save Downloads folder (shared across machines)"
  Write-Host "   bk myproject             Jump to myproject bookmark"
  Write-Host "   bk myproject -F          Open myproject in Finder"
  Write-Host "   bk list                  Show all bookmarks with [L] indicator"
  Write-Host "   bk remove myproject      Delete myproject (checks local first)"
  Write-Host ""
}
