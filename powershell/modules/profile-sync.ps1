# ================================================================
# PROFILE MANAGEMENT & GIST SYNC
# ================================================================
# Simplified sync system: Auto-discover all files, no state tracking

# Path to ignored dependencies file (machine-specific, not synced)
$script:IgnoredDepsPath = Join-Path $script:ProfileDir '.ignored-dependencies.json'

# Helper: Load ignored dependencies list
function Get-IgnoredDependencies {
  if (-not (Test-Path $script:IgnoredDepsPath)) {
    return @()
  }
  
  try {
    $data = Get-Content $script:IgnoredDepsPath -Raw | ConvertFrom-Json
    return $data.PSObject.Properties.Name
  } catch {
    Write-Warning "Failed to load ignored dependencies: $_"
    return @()
  }
}

# Helper: Save ignored dependencies list
function Save-IgnoredDependencies {
  param([string[]]$Dependencies)
  
  $obj = [PSCustomObject]@{}
  foreach ($dep in $Dependencies) {
    if ($dep) {  # Skip null/empty entries
      $obj | Add-Member -NotePropertyName $dep -NotePropertyValue $true
    }
  }
  
  $obj | ConvertTo-Json | Set-Content $script:IgnoredDepsPath -Encoding UTF8
}

# Helper: Check if a dependency is ignored
function Test-DependencyIgnored {
  param([string]$Dependency)
  
  $ignored = Get-IgnoredDependencies
  return $ignored -contains $Dependency
}

# Helper: Process and save files from a gist response
function Save-GistFiles {
  param(
    [Parameter(Mandatory)]
    $Gist,
    [string]$GistType = "public"
  )
  
  $updatedCount = 0
  
  foreach ($gistFile in $Gist.files.PSObject.Properties) {
    $flattenedName = $gistFile.Name
    $content = $gistFile.Value.content
    
    # Determine actual file path
    if ($flattenedName -eq 'profile.ps1') {
      $fullPath = $PROFILE
    } else {
      $actualPath = $flattenedName -replace '--', '/'
      $fullPath = Join-Path $script:ProfileDir $actualPath
    }
    
    # Ensure parent directory exists
    $parentDir = Split-Path -Parent $fullPath
    if ($parentDir -and -not (Test-Path $parentDir)) {
      New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }
    
    # Save file
    Set-Content -Path $fullPath -Value $content -Encoding UTF8
    $updatedCount++
  }
  
  return $updatedCount
}

# Helper: Determine which gist a file belongs to based on its path
function Get-GistForFile {
  param([string]$FlattenedName)
  
  # Files in private-modules go to private gist
  if ($FlattenedName -like 'private-modules--*') {
    return 'private'
  }
  
  # Everything else goes to public gist
  return 'public'
}

# Helper: Convert flattened gist name to user-friendly path
function ConvertTo-UserFriendlyPath {
  param([string]$FlattenedName)
  # Convert double-dash back to forward slash for display
  return $FlattenedName -replace '--', '/'
}

# Helper: Calculate hash of file content
function Get-FileContentHash {
  param([string]$Path)
  if (-not (Test-Path $Path)) { return $null }
  $content = Get-Content -Path $Path -Raw -Encoding UTF8
  
  # Handle empty files - use empty string for hash calculation
  if ($null -eq $content) {
    $content = ''
  }
  
  $hash = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
  $hashBytes = $hash.ComputeHash($bytes)
  return [BitConverter]::ToString($hashBytes).Replace('-', '').ToLower()
}

# Helper: Auto-discover all profile files (no state file needed)
function Get-ProfileFilesState {
  $files = @{}
  
  # Exclusion list
  $excludeFiles = @(
    'Microsoft.PowerShell_profile.ps1',  # Syncs as profile.ps1 instead
    '.ignored-dependencies.json',        # Machine-specific, not synced
    '.DS_Store',
    '.gitignore',
    '.gitignore.backup'
  )

  # Root files
  Get-ChildItem -Path $script:ProfileDir -File | ForEach-Object {
    if ($excludeFiles -notcontains $_.Name) {
      $files[$_.Name] = $_.FullName
    }
  }
  
  # profile.ps1 special mapping
  if (Test-Path $PROFILE) {
    $files['profile.ps1'] = $PROFILE
  }
  
  # modules/*.ps1
  $modulesDir = Join-Path $script:ProfileDir 'modules'
  if (Test-Path $modulesDir) {
    Get-ChildItem -Path $modulesDir -Filter '*.ps1' -File | ForEach-Object {
      $flattenedName = "modules--$($_.Name)"
      $files[$flattenedName] = $_.FullName
    }
  }
  
  # private-modules/**/*.ps1 (🔒 SECURITY: These go to private gist only)
  # Supports nested subdirectories (e.g., private-modules/powershell/modules/obvio.ps1)
  $privateModulesDir = Join-Path $script:ProfileDir 'private-modules'
  if (Test-Path $privateModulesDir) {
    Get-ChildItem -Path $privateModulesDir -Filter '*.ps1' -File -Recurse | ForEach-Object {
      # Get relative path from private-modules directory
      $relativePath = $_.FullName.Substring($privateModulesDir.Length + 1)
      # Replace directory separators with double-dash
      $flattenedName = "private-modules--$($relativePath -replace '[/\\]', '--')"
      $files[$flattenedName] = $_.FullName
    }
  }
  
  # scripts/*.ps1
  $scriptsDir = Join-Path $script:ProfileDir 'scripts'
  if (Test-Path $scriptsDir) {
    Get-ChildItem -Path $scriptsDir -Filter '*.ps1' -File | ForEach-Object {
      $flattenedName = "scripts--$($_.Name)"
      $files[$flattenedName] = $_.FullName
    }
  }
  
  return $files
}


# Helper: Get list of files currently in gist (names only)
function Get-GistFileList {
  param(
    [string]$GitHubToken,
    [string]$GistId = $script:GistId
  )
  
  if (-not $GitHubToken) {
    Write-Warning "Cannot fetch gist file list: GITHUB_GIST_TOKEN not set"
    return @()
  }
  
  try {
    $gistUrl = "https://api.github.com/gists/$GistId"
    $headers = @{
      'User-Agent' = 'PowerShell'
      'Authorization' = "Bearer $GitHubToken"
    }
    
    $gist = Invoke-RestMethod -Uri $gistUrl -Headers $headers
    return $gist.files.PSObject.Properties.Name
  }
  catch {
    Write-Warning "Failed to fetch gist file list: $_"
    return @()
  }
}


function profile {
  Param(
    [Parameter(Mandatory = $false, Position = 0)]
    [String]$Command,
    [Parameter(Mandatory = $false, Position = 1)]
    [String]$FilePath,
    [switch]$Force
  )

  # Normalize short aliases to full names
  $normalizedCommand = switch ($Command) {
    'h'  { 'help' }
    'ss' { 'setup-scripts'}
    'push' { 'ps' }
    'pull' { 'pl' }
    'w' { 'web'}
    'p' { 'path'}
    'd' { 'dir'}
    'f' { 'folder'}
    default { $Command }
  }

  Switch ($normalizedCommand) {
    # help
    'help' {
      Show-ProfileSyncHelp
    }
    # Push all profile files to Gist (auto-discover)
    'ps' {
      $GitHubToken = $env:GITHUB_GIST_TOKEN

      if (-not $GitHubToken) {
        Write-Error "GITHUB_GIST_TOKEN environment variable is not set. Create a token at https://github.com/settings/tokens with 'gist' scope."
        return
      }

      try {
        # Prepare headers
        $headers = @{
          'User-Agent' = 'PowerShell'
          'Authorization' = "Bearer $GitHubToken"
          'Content-Type' = 'application/json'
        }

        # Auto-discover all files
        Write-Host "🔍 Auto-discovering files..." -ForegroundColor Cyan
        $allFiles = Get-ProfileFilesState
        
        # Separate files into public and private (🔒 SECURITY CRITICAL)
        $publicFiles = @{}
        $privateFiles = @{}
        
        foreach ($flattenedName in $allFiles.Keys) {
          $fullPath = $allFiles[$flattenedName]
          
          # Read content
          if (Test-Path $fullPath) {
            $content = Get-Content -Path $fullPath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
            if ($null -eq $content) { $content = '' }
            
            # Route to appropriate gist (🔒 SECURITY: private-modules go to private gist)
            $gistType = Get-GistForFile -FlattenedName $flattenedName
            if ($gistType -eq 'private') {
              $privateFiles[$flattenedName] = @{ content = $content }
            } else {
              $publicFiles[$flattenedName] = @{ content = $content }
            }
          }
        }
        
        $publicCount = $publicFiles.Count
        $privateCount = $privateFiles.Count
        Write-Host "Found $publicCount public file(s) and $privateCount private file(s) to sync" -ForegroundColor Gray
        
        # Sync to PUBLIC GIST
        if ($publicCount -gt 0) {
          Write-Host "`n📦 Syncing to PUBLIC gist..." -ForegroundColor Cyan
          $publicGistUrl = "https://api.github.com/gists/$($script:GistId)"
          
          # Deletion detection for public gist
          Write-Host "Checking for files to delete from public gist..." -ForegroundColor Gray
          $publicGistFiles = Get-GistFileList -GitHubToken $GitHubToken -GistId $script:GistId
          $publicLocalFiles = $publicFiles.Keys
          $publicFilesToDelete = $publicGistFiles | Where-Object { $_ -notin $publicLocalFiles }
          
          if ($publicFilesToDelete.Count -gt 0) {
            Write-Host "⚠️  $($publicFilesToDelete.Count) file(s) in public gist but not locally" -ForegroundColor Yellow
            $shouldDelete = $false
            if ($Force) {
              Write-Host "🔥 -Force flag set: Deleting files automatically" -ForegroundColor Yellow
              $shouldDelete = $true
            } else {
              $response = Read-Host "Remove $($publicFilesToDelete.Count) file(s) from public gist? [y/N]"
              $shouldDelete = $response -eq 'y' -or $response -eq 'Y'
            }
            
            if ($shouldDelete) {
              foreach ($file in $publicFilesToDelete) {
                $publicFiles[$file] = $null
              }
              Write-Host "✓ Will delete $($publicFilesToDelete.Count) file(s)" -ForegroundColor Cyan
            } else {
              Write-Host "✓ Skipping deletion" -ForegroundColor Cyan
            }
          } else {
            Write-Host "✓ No files to delete from public gist" -ForegroundColor Gray
          }
          
          $publicBody = @{ files = $publicFiles } | ConvertTo-Json -Depth 3
          $null = Invoke-RestMethod -Uri $publicGistUrl -Method Patch -Headers $headers -Body $publicBody
          Write-Host "✅ Successfully saved $publicCount file(s) to PUBLIC gist!" -ForegroundColor Green
        } else {
          Write-Host "`n📦 No public files to sync" -ForegroundColor Gray
        }
        
        # Sync to PRIVATE GIST
        if ($privateCount -gt 0) {
          if (-not $script:PrivateGistId) {
            Write-Host "`n⚠️  Skipping private files: POWERSHELL_PRIVATE_GIST_ID not set" -ForegroundColor Yellow
            Write-Host "   Set environment variable: POWERSHELL_PRIVATE_GIST_ID=<gist-id>" -ForegroundColor Gray
          } else {
            Write-Host "`n🔒 Syncing to PRIVATE gist..." -ForegroundColor Cyan
            $privateGistUrl = "https://api.github.com/gists/$($script:PrivateGistId)"
            
            # Deletion detection for private gist
            Write-Host "Checking for files to delete from private gist..." -ForegroundColor Gray
            $privateGistFiles = Get-GistFileList -GitHubToken $GitHubToken -GistId $script:PrivateGistId
            $privateLocalFiles = $privateFiles.Keys
            $privateFilesToDelete = $privateGistFiles | Where-Object { $_ -notin $privateLocalFiles }
            
            if ($privateFilesToDelete.Count -gt 0) {
              Write-Host "⚠️  $($privateFilesToDelete.Count) file(s) in private gist but not locally" -ForegroundColor Yellow
              $shouldDelete = $false
              if ($Force) {
                Write-Host "🔥 -Force flag set: Deleting files automatically" -ForegroundColor Yellow
                $shouldDelete = $true
              } else {
                $response = Read-Host "Remove $($privateFilesToDelete.Count) file(s) from private gist? [y/N]"
                $shouldDelete = $response -eq 'y' -or $response -eq 'Y'
              }
              
              if ($shouldDelete) {
                foreach ($file in $privateFilesToDelete) {
                  $privateFiles[$file] = $null
                }
                Write-Host "✓ Will delete $($privateFilesToDelete.Count) file(s)" -ForegroundColor Cyan
              } else {
                Write-Host "✓ Skipping deletion" -ForegroundColor Cyan
              }
            } else {
              Write-Host "✓ No files to delete from private gist" -ForegroundColor Gray
            }
            
            $privateBody = @{ files = $privateFiles } | ConvertTo-Json -Depth 3
            $null = Invoke-RestMethod -Uri $privateGistUrl -Method Patch -Headers $headers -Body $privateBody
            Write-Host "✅ Successfully saved $privateCount file(s) to PRIVATE gist!" -ForegroundColor Green
          }
        } else {
          Write-Host "`n🔒 No private files to sync" -ForegroundColor Gray
        }
        
        Write-Host "`n🎉 Sync complete!" -ForegroundColor Green
      }
      catch {
        Write-Error "Failed to save profile: $_"
      }
    }
    # Pull all files from Gist (creates backup)
    'pl' { 
      try {
        $headers = @{ 'User-Agent' = 'PowerShell' }
        
        # Create backup first
        $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $backupParent = Join-Path $script:ProfileDir "backup"
        $backupDir = Join-Path $backupParent $timestamp
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        Write-Host "Creating backup in: backup/$timestamp" -ForegroundColor Yellow
        
        # Backup current files
        if (Test-Path $PROFILE) {
          Copy-Item -Path $PROFILE -Destination (Join-Path $backupDir (Split-Path -Leaf $PROFILE)) -Force
          Write-Host "  ✓ Backed up profile" -ForegroundColor Gray
        }
        
        $modulesDir = Join-Path $script:ProfileDir 'modules'
        if (Test-Path $modulesDir) {
          $backupModulesDir = Join-Path $backupDir 'modules'
          Copy-Item -Path $modulesDir -Destination $backupModulesDir -Recurse -Force
          Write-Host "  ✓ Backed up modules/" -ForegroundColor Gray
        }
        
        $privateModulesDir = Join-Path $script:ProfileDir 'private-modules'
        if (Test-Path $privateModulesDir) {
          $backupPrivateModulesDir = Join-Path $backupDir 'private-modules'
          Copy-Item -Path $privateModulesDir -Destination $backupPrivateModulesDir -Recurse -Force
          Write-Host "  ✓ Backed up private-modules/" -ForegroundColor Gray
        }
        
        $scriptsDir = Join-Path $script:ProfileDir 'scripts'
        if (Test-Path $scriptsDir) {
          $backupScriptsDir = Join-Path $backupDir 'scripts'
          Copy-Item -Path $scriptsDir -Destination $backupScriptsDir -Recurse -Force
          Write-Host "  ✓ Backed up scripts/" -ForegroundColor Gray
        }
        
        # Pull from PUBLIC GIST
        Write-Host "`n📦 Pulling from PUBLIC gist..." -ForegroundColor Cyan
        $publicGistUrl = "https://api.github.com/gists/$($script:GistId)"
        $publicGist = Invoke-RestMethod -Uri $publicGistUrl -Headers $headers
        
        if (-not $publicGist.files.'profile.ps1') {
          Write-Error "No file named 'profile.ps1' found in the public gist."
          return
        }
        
        $publicCount = Save-GistFiles -Gist $publicGist -GistType "public"
        Write-Host "✅ Pulled $publicCount file(s) from PUBLIC gist" -ForegroundColor Green
        
        # Pull from PRIVATE GIST (if configured)
        if ($script:PrivateGistId) {
          Write-Host "`n🔒 Pulling from PRIVATE gist..." -ForegroundColor Cyan
          
          # Private gist requires token
          $GitHubToken = $env:GITHUB_GIST_TOKEN
          if (-not $GitHubToken) {
            Write-Host "⚠️  Skipping private gist: GITHUB_GIST_TOKEN not set" -ForegroundColor Yellow
          } else {
            try {
              $privateHeaders = @{
                'User-Agent' = 'PowerShell'
                'Authorization' = "Bearer $GitHubToken"
              }
              $privateGistUrl = "https://api.github.com/gists/$($script:PrivateGistId)"
              $privateGist = Invoke-RestMethod -Uri $privateGistUrl -Headers $privateHeaders
              
              $privateCount = Save-GistFiles -Gist $privateGist -GistType "private"
              Write-Host "✅ Pulled $privateCount file(s) from PRIVATE gist" -ForegroundColor Green
            }
            catch {
              Write-Host "⚠️  Failed to pull from private gist: $_" -ForegroundColor Yellow
            }
          }
        }
        
        Write-Host "`n✅ Profile successfully restored from gist!" -ForegroundColor Green
        Write-Host "Restart PowerShell or run '. `$PROFILE' to reload." -ForegroundColor Cyan
      }
      catch {
        Write-Error "Failed to update profile: $_"
      }
    }
    # show profile path
    'path' {
      Write-Host "Profile location: $PROFILE" -ForegroundColor Cyan
    }
    # navigate to profile directory
    'dir' {
      Write-Host "📁 Navigated to: $script:ProfileDir" -ForegroundColor Cyan
      Set-Location $script:ProfileDir
    }
    # open profile directory in Finder
    'folder' {
      Write-Host "📂 Opening in Finder: $script:ProfileDir" -ForegroundColor Cyan
      & open -a Finder $script:ProfileDir
    }
    # open GitHub Gist in browser
    'web' {
      $gistWebUrl = "https://gist.github.com/$($script:GistId)"
      Write-Host "🌐 Opening GitHub Gist: $gistWebUrl" -ForegroundColor Cyan
      & open $gistWebUrl
    }
    # setup executable permissions for scripts (ZoomISO, etc.)
    'setup-scripts' {
      $scriptsDir = Join-Path $script:ProfileDir 'scripts'
      
      if (-not (Test-Path $scriptsDir)) {
        Write-Host "❌ Scripts directory not found: $scriptsDir" -ForegroundColor Red
        Write-Host "   Run 'profile pl' to pull scripts from gist" -ForegroundColor Yellow
        return
      }
      
      $scriptFiles = Get-ChildItem -Path $scriptsDir -Filter '*.ps1'
      
      if ($scriptFiles.Count -eq 0) {
        Write-Host "⚠️  No script files found in: $scriptsDir" -ForegroundColor Yellow
        return
      }
      
      Write-Host "Setting up executable permissions for scripts..." -ForegroundColor Cyan
      
      foreach ($scriptFile in $scriptFiles) {
        chmod +x $scriptFile.FullName
        Write-Host "  ✓ Made executable: $($scriptFile.Name)" -ForegroundColor Gray
      }
      
      Write-Host "`n✅ Set up $($scriptFiles.Count) script files" -ForegroundColor Green
      Write-Host "`nAvailable scripts:" -ForegroundColor Cyan
      foreach ($scriptFile in $scriptFiles) {
        Write-Host "  pwsh $($scriptFile.FullName)" -ForegroundColor Gray
      }
    }
    # ignore dependency warnings
    'ignore-dep' {
      if (-not $FilePath) {
        Write-Host "❌ Missing dependency name" -ForegroundColor Red
        Write-Host "Usage: profile ignore-dep <name>" -ForegroundColor Yellow
        Write-Host "Available: gh, git, docker, fnm, copilot, font, private-gist-id" -ForegroundColor Gray
        return
      }
      
      $depName = $FilePath.ToLower()
      $validDeps = @('gh', 'git', 'docker', 'fnm', 'copilot', 'font', 'private-gist-id')
      
      if ($validDeps -notcontains $depName) {
        Write-Host "❌ Invalid dependency: $depName" -ForegroundColor Red
        Write-Host "Available: $($validDeps -join ', ')" -ForegroundColor Yellow
        return
      }
      
      $ignored = @(Get-IgnoredDependencies)
      if ($ignored -contains $depName) {
        Write-Host "ℹ️  Dependency '$depName' is already ignored" -ForegroundColor Cyan
        return
      }
      
      $ignored += $depName
      Save-IgnoredDependencies -Dependencies $ignored
      Write-Host "✅ Suppressed warnings for: $depName" -ForegroundColor Green
      Write-Host "   (Restart terminal to take effect)" -ForegroundColor DarkGray
    }
    # unignore dependency warnings
    'unignore-dep' {
      if (-not $FilePath) {
        Write-Host "❌ Missing dependency name" -ForegroundColor Red
        Write-Host "Usage: profile unignore-dep <name>" -ForegroundColor Yellow
        return
      }
      
      $depName = $FilePath.ToLower()
      $ignored = @(Get-IgnoredDependencies)
      
      if ($ignored -notcontains $depName) {
        Write-Host "ℹ️  Dependency '$depName' is not currently ignored" -ForegroundColor Cyan
        return
      }
      
      $ignored = $ignored | Where-Object { $_ -ne $depName }
      Save-IgnoredDependencies -Dependencies $ignored
      Write-Host "✅ Re-enabled warnings for: $depName" -ForegroundColor Green
      Write-Host "   (Restart terminal to take effect)" -ForegroundColor DarkGray
    }
    # list ignored dependencies
    'list-ignored' {
      $ignored = Get-IgnoredDependencies
      
      if ($ignored.Count -eq 0) {
        Write-Host "No dependencies are currently ignored" -ForegroundColor Gray
        Write-Host "Use 'profile ignore-dep <name>' to suppress warnings" -ForegroundColor Yellow
        return
      }
      
      Write-Host "🔕 Ignored Dependencies:" -ForegroundColor Cyan
      foreach ($dep in $ignored) {
        Write-Host "   • $dep" -ForegroundColor Gray
      }
      Write-Host "`nTo re-enable: profile unignore-dep <name>" -ForegroundColor DarkGray
    }
    # default: open profile in VS Code
    default { 
      code $PROFILE
    }
  }
}

Set-Alias -Name pf -Value profile
Set-Alias -Name pl -Value profile



# ================================================================
# HELP FUNCTION
# ================================================================

function Show-ProfileSyncHelp {
  Write-Host "  PROFILE MANAGEMENT" -ForegroundColor Green
  Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
  Write-Host "  Get Help: help profile  OR  profile help  OR  profile h" -ForegroundColor Gray
  Write-Host ""
  Write-Host "⚙️  PROFILE COMMANDS" -ForegroundColor Yellow
  Write-Host "   profile                    Open profile in VS Code"
  Write-Host "   profile path (p)           Show profile file path"
  Write-Host "   profile dir (d)            Navigate to profile directory"
  Write-Host "   profile folder (f)         Open profile directory in Finder"
  Write-Host "   profile web (w)            Open GitHub Gist in browser"
  Write-Host "   profile ps [-Force]        Push all files to GitHub Gist (auto-discovers)"
  Write-Host "   profile pl                 Pull all files from GitHub Gist (creates backup)"
  Write-Host "   profile setup-scripts (ss) Make scripts executable (after pull)"
  Write-Host "   profile ignore-dep <name>  Suppress dependency warnings for this machine"
  Write-Host "   profile unignore-dep <name>Re-enable dependency warnings"
  Write-Host "   profile list-ignored       Show ignored dependencies"
  Write-Host ""
  Write-Host "💡 EXAMPLES" -ForegroundColor Yellow
  Write-Host "   profile                  Edit profile in VS Code"
  Write-Host "   profile ps               Push all changes to gist"
  Write-Host "   profile ps -Force        Push without confirmation prompts"
  Write-Host "   profile pl               Pull from gist (backup created automatically)"
  Write-Host ""
}
