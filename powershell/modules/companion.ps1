# ================================================================
# COMPANION MODULE MANAGEMENT
# ================================================================
# Unified management for Companion module projects using yarn

$script:CompanionModuleDevRoot = Join-Path $HOME 'Development/companion-module-dev'

# Define all companion modules with their directory names
$script:CompanionModules = [ordered]@{
  'hdtv'   = @{ Path = 'companion-module-hdtv-wolfpackgreen'; Name = 'HDTV WolfPack Green' }
  'wiz'    = @{ Path = 'companion-module-philips-wiz-bulbs'; Name = 'Philips Wiz Bulbs' }
  'ztiles' = @{ Path = 'companion-module-zoom-tiles'; Name = 'Zoom Tiles' }
  'lobs'   = @{ Path = 'companion-module-lynbh-obs'; Name = 'LYNBH OBS' }
  'zosc'   = @{ Path = 'companion-module-zoom-osc-iso'; Name = 'Zoom OSC ISO' }
  'key'    = @{ Path = 'companion-module-elgato-keylight'; Name = 'Elgato Keylight' }
}

function Invoke-CompanionAction {
  <#
  .SYNOPSIS
    Internal function to perform actions on companion modules
  .PARAMETER ModuleKey
    The module key (hdtv, wiz, ztiles, lobs, zosc)
  .PARAMETER Action
    The action to perform (deps, update, dev, build)
  #>
  param(
    [Parameter(Mandatory)]
    [string]$ModuleKey,
    
    [Parameter(Mandatory)]
    [ValidateSet('deps', 'update', 'dev', 'build')]
    [string]$Action
  )
  
  $module = $script:CompanionModules[$ModuleKey]
  $modulePath = Join-Path $script:CompanionModuleDevRoot $module.Path
  
  if (-not (Test-Path $modulePath)) {
    Write-Host "❗ Module path not found: $modulePath" -ForegroundColor Red
    return
  }
  
  # Navigate to the module directory and stay there
  Set-Location $modulePath
  Write-Host "📁 In: $modulePath" -ForegroundColor DarkGray
  Write-Host ""
  
  switch ($Action) {
    'deps' {
      Write-Host "📦 Installing dependencies for $($module.Name)..." -ForegroundColor Cyan
      yarn install
      if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Dependencies installed for $($module.Name)" -ForegroundColor Green
      }
    }
    
    'update' {
      Write-Host "🔄 Updating $($module.Name) from git..." -ForegroundColor Cyan
      git pull --prune
      if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ $($module.Name) updated from git" -ForegroundColor Green
      }
    }
    
    'dev' {
      Write-Host "🚀 Starting dev mode for $($module.Name)..." -ForegroundColor Cyan
      Write-Host "   (This will run in the current terminal)" -ForegroundColor Gray
      yarn dev
    }
    
    'build' {
      Write-Host "🔨 Building $($module.Name)..." -ForegroundColor Cyan
      yarn build
      if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ $($module.Name) built successfully" -ForegroundColor Green
      }
    }
  }
}

function Invoke-Companion {
  <#
  .SYNOPSIS
    Unified command for Companion module management
  .DESCRIPTION
    Provides centralized access to all Companion module operations including
    dependency installation, git updates, and development server management.
    Supports both full and short command names (nav/n, dev/d, update/u, build/b, deps/ds).
  .PARAMETER Action
    The action to perform: help, nav/n, update-all, deps/ds, update/u, dev/d, build/b
  .PARAMETER Module
    The module to perform the action on (required for deps, update, dev, build)
  .EXAMPLE
    comp help
    Display all available Companion module commands
  .EXAMPLE
    cm update-all
    Update all modules from git
  .EXAMPLE
    comp ds hdtv
    Install dependencies for HDTV module (short form)
  .EXAMPLE
    cm d wiz
    Start dev server for Wiz Bulbs module (short form)
  .ALIAS
    comp, cm
  #>
  param(
    [Parameter(Position=0)]
    [ValidateSet('h', 'help', 'nav', 'n', 'update-all', 'deps', 'ds', 'update', 'u', 'dev', 'd', 'build', 'b')]
    [string]$Action = 'help',
    
    [Parameter(Position=1)]
    [ValidateSet('root', 'hdtv', 'wiz', 'ztiles', 'lobs', 'zosc', 'key')]
    [string]$Module
  )
  
  # Normalize short aliases to full names
  $normalizedAction = switch ($Action) {
    'n'  { 'nav' }
    'ds' { 'deps' }
    'u'  { 'update' }
    'd'  { 'dev' }
    'b'  { 'build' }
    'h'  { 'help' }
    default { $Action }
  }
  
  switch ($normalizedAction) {
    'help' {
      Write-Host ""
      Write-Host "======= COMPANION MODULE MANAGEMENT =======" -ForegroundColor Green
      Write-Host "  Get Help: help companion  OR  comp help  OR  cm help" -ForegroundColor Gray
      Write-Host ""
      Write-Host "  Aliases: comp, cm, companion" -ForegroundColor Gray
      Write-Host ""
      Write-Host "------- NAVIGATION" -ForegroundColor Yellow
      Write-Host "comp nav | n              -> Navigate to root directory"
      Write-Host "comp nav | n <module>     -> Navigate to module (e.g., comp n hdtv)"
      Write-Host ""
      Write-Host "------- BULK OPERATIONS" -ForegroundColor Yellow
      Write-Host "comp update-all           -> Update all modules from git"
      Write-Host ""
      Write-Host "------- INDIVIDUAL MODULE ACTIONS" -ForegroundColor Yellow
      Write-Host "comp deps | ds <module>   -> Install dependencies (e.g., cm ds hdtv)"
      Write-Host "comp update | u <module>  -> Update from git (git pull)"
      Write-Host "comp dev | d <module>     -> Start dev server (yarn dev)"
      Write-Host "comp build | b <module>   -> Build module (yarn build)"
      Write-Host ""
      Write-Host "------- AVAILABLE MODULES" -ForegroundColor Yellow
      foreach ($key in $script:CompanionModules.Keys) {
        $mod = $script:CompanionModules[$key]
        Write-Host "$key -> $($mod.Path) ($($mod.Name))"
      }
      Write-Host ""
      Write-Host "TIP: Use 'comp' or 'cm' as the command" -ForegroundColor DarkGray
      Write-Host ""
    }
    
    'nav' {
      if (-not $Module -or $Module -eq 'root') {
        # Navigate to root
        if (-not (Test-Path -LiteralPath $script:CompanionModuleDevRoot)) {
          Write-Host "❗ Root path not found: $script:CompanionModuleDevRoot" -ForegroundColor Red
          return
        }
        Set-Location -LiteralPath $script:CompanionModuleDevRoot
        Write-Host "📁 Navigated to Companion Module Dev root" -ForegroundColor Cyan
      }
      else {
        # Navigate to specific module
        if (-not $script:CompanionModules.Contains($Module)) {
          Write-Host "❗ Unknown module: $Module" -ForegroundColor Red
          Write-Host "Available modules: hdtv, wiz, ztiles, lobs, zosc" -ForegroundColor Gray
          return
        }
        
        $mod = $script:CompanionModules[$Module]
        $targetPath = Join-Path $script:CompanionModuleDevRoot $mod.Path
        
        if (-not (Test-Path -LiteralPath $targetPath)) {
          Write-Host "❗ Module path not found: $targetPath" -ForegroundColor Red
          return
        }
        
        Set-Location -LiteralPath $targetPath
        Write-Host "📁 Navigated to $($mod.Name)" -ForegroundColor Cyan
      }
    }
    
    'update-all' {
      Write-Host "🔄 Updating all Companion modules from git..." -ForegroundColor Cyan
      Write-Host ""
      foreach ($key in $script:CompanionModules.Keys) {
        Invoke-CompanionAction -ModuleKey $key -Action 'update'
        Write-Host ""
      }
      Write-Host "✅ All modules have been updated" -ForegroundColor Green
    }
    
    { $_ -in @('deps', 'update', 'dev', 'build') } {
      if (-not $Module) {
        Write-Host "❗ Module parameter is required for action '$Action'" -ForegroundColor Red
        Write-Host "Usage: comp $Action <module>" -ForegroundColor Yellow
        Write-Host "Available modules: hdtv, wiz, ztiles, lobs, zosc" -ForegroundColor Gray
        return
      }
      
      # Validate module exists
      if (-not $script:CompanionModules.Contains($Module)) {
        Write-Host "❗ Unknown module: $Module" -ForegroundColor Red
        Write-Host "Available modules: hdtv, wiz, ztiles, lobs, zosc" -ForegroundColor Gray
        return
      }
      
      # Call the action with normalized name
      Invoke-CompanionAction -ModuleKey $Module -Action $normalizedAction
    }
  }
}

# Aliases for convenience
Set-Alias -Name comp -Value Invoke-Companion
Set-Alias -Name cm -Value Invoke-Companion
Set-Alias -Name companion -Value Invoke-Companion


# ================================================================
# HELP FUNCTION
# ================================================================

function Show-CompanionHelp {
  # Call the built-in companion help which shows dynamic module list
  companion help
}
