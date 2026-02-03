# ================================================================
# GIT SHORTCUTS
# ================================================================

<#
.SYNOPSIS
    Git command shortcuts
.DESCRIPTION
    Quick aliases for common git commands using single letters.
    Includes branch management (br) and stash operations (st).
    Alias: g
.PARAMETER Command
    Short command:
      a     = add           pl    = pull          ll    = pretty log
      b     = branch        ps    = push          m     = merge
      c     = checkout      r     = rebase        rs    = reset
      cl    = clone         s     = status        t     = tag
      co    = commit        f     = fetch         l     = log
      cm    = add + commit (with message)
      cp    = add + commit + push (with message)
      amend = amend last commit (optional new message)
      br    = branch management (new, del, clean, rename)
      st    = stash operations (list, show, pop, drop)
      i     = init
.PARAMETER Parameters
    Additional parameters passed to git command
.EXAMPLE
    g s                      # git status
    g cm "Add feature"       # git add . && commit
    g cp "Fix bug"           # git add . && commit && push
    g br                     # list branches
    g br new feature/auth    # create new branch
    g br clean               # delete merged branches
    g st                     # stash with timestamp
    g st list                # list stashes
    g st pop                 # pop latest stash
.ALIAS
    g
#>
function Invoke-Git {
  [Alias('g')]
  Param(
    [Parameter(Mandatory = $true, Position = 0)]
    [Alias("cmd")]
    [String]
    $Command,
    [Parameter(Mandatory = $false, ValueFromRemainingArguments = $true)]
    [Alias("params")]
    [String[]]
    $Parameters
  )

  $normalizedCommand = switch ($Command) {
    'h'  { 'help' }
    default
     { $Command }
  }

  Switch ($normalizedCommand) {
    # help
    'help' { Show-GitHelp }
    # add
    'a' { git add $Parameters }
    # branch (simple)
    'b' { git branch $Parameters }
    # checkout
    'c' { git checkout $Parameters }
    # clone repo
    'cl' { git clone $Parameters }
    # commit
    'co' { git commit $Parameters }
    # commit with add (cm = commit message)
    'cm' {
      if (-not $Parameters) {
        Write-Host "Usage: g cm 'commit message'" -ForegroundColor Yellow
        return
      }
      $commitMsg = $Parameters -join ' '
      git add .
      git commit -m $commitMsg
    }
    # commit and push with add (cp = commit push)
    'cp' {
      if (-not $Parameters) {
        Write-Host "Usage: g cp 'commit message'" -ForegroundColor Yellow
        return
      }
      $commitMsg = $Parameters -join ' '
      git add .
      git commit -m $commitMsg
      git push
    }
    # amend last commit
    'amend' {
      git add .
      if ($Parameters) {
        $commitMsg = $Parameters -join ' '
        git commit --amend -m $commitMsg
      } else {
        git commit --amend --no-edit
      }
    }
    # branch management (br)
    'br' {
      if (-not $Parameters) {
        # No params - list branches
        git branch -v --sort=-committerdate
        return
      }

      $subCmd = $Parameters[0]
      $subParams = $Parameters[1..($Parameters.Length - 1)]

      switch ($subCmd) {
        'new' {
          if (-not $subParams) {
            Write-Host "Usage: g br new <branch-name>" -ForegroundColor Yellow
            Write-Host "Examples:" -ForegroundColor Cyan
            Write-Host "  g br new feature/auth-system" -ForegroundColor Gray
            Write-Host "  g br new fix/login-bug" -ForegroundColor Gray
            Write-Host "  g br new chore/update-deps" -ForegroundColor Gray
            return
          }
          $branchName = $subParams -join ' '
          git checkout -b $branchName
        }
        'del' {
          if (-not $subParams) {
            Write-Host "Usage: g br del <branch-name>  (safe delete, checks if merged)" -ForegroundColor Yellow
            return
          }
          $branchName = $subParams -join ' '
          git branch -d $branchName
        }
        'Del' {
          if (-not $subParams) {
            Write-Host "Usage: g br Del <branch-name>  (FORCE delete, no checks)" -ForegroundColor Yellow
            return
          }
          $branchName = $subParams -join ' '
          git branch -D $branchName
        }
        'clean' {
          Write-Host "Cleaning merged branches..." -ForegroundColor Cyan
          $defaultBranch = git symbolic-ref refs/remotes/origin/HEAD 2>&1 | Where-Object { $_ -notmatch 'fatal' } | ForEach-Object { $_ -replace '^refs/remotes/origin/', '' }
          if (-not $defaultBranch) {
            if (git rev-parse --verify main 2>&1 | Select-Object -First 1 | Where-Object { $_ -notmatch 'fatal' }) { $defaultBranch = "main" }
            elseif (git rev-parse --verify master 2>&1 | Select-Object -First 1 | Where-Object { $_ -notmatch 'fatal' }) { $defaultBranch = "master" }
            else {
              Write-Host "Could not determine default branch (main/master)" -ForegroundColor Red
              return
            }
          }
          
          $currentBranch = git rev-parse --abbrev-ref HEAD
          $mergedBranches = git branch --merged $defaultBranch | 
            Where-Object { $_ -notmatch '^\*' -and $_ -notmatch $defaultBranch -and $_.Trim() -ne $currentBranch } |
            ForEach-Object { $_.Trim() }
          
          if ($mergedBranches) {
            Write-Host "Branches merged into $defaultBranch (excluding current):" -ForegroundColor Yellow
            $mergedBranches | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
            Write-Host ""
            $confirm = Read-Host "Delete these branches? (y/N)"
            if ($confirm -eq 'y' -or $confirm -eq 'Y') {
              $mergedBranches | ForEach-Object { git branch -d $_ }
              Write-Host "✅ Cleaned merged branches" -ForegroundColor Green
            } else {
              Write-Host "Cancelled" -ForegroundColor Yellow
            }
          } else {
            Write-Host "No merged branches to clean" -ForegroundColor Green
          }
        }
        'rename' {
          if (-not $subParams) {
            Write-Host "Usage: g br rename <new-name>" -ForegroundColor Yellow
            return
          }
          $newName = $subParams -join ' '
          git branch -m $newName
        }
        default {
          git branch $subCmd $subParams
        }
      }
    }
    # stash operations (st)
    'st' {
      if (-not $Parameters) {
        # No params - stash with timestamp
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        git stash push -m "Stash at $timestamp"
        return
      }

      $subCmd = $Parameters[0]
      $subParams = $Parameters[1..($Parameters.Length - 1)]

      # If subCmd is not a known stash command, treat it as a message
      if ($subCmd -notin @('list', 'show', 'pop', 'apply', 'drop', 'clear')) {
        $message = $Parameters -join ' '
        git stash push -m $message
        return
      }

      switch ($subCmd) {
        'list' {
          git stash list
        }
        'show' {
          if ($subParams) {
            $index = $subParams[0]
            git stash show -p "stash@{$index}"
          } else {
            git stash show -p
          }
        }
        'pop' {
          git stash pop
        }
        'apply' {
          if ($subParams) {
            $index = $subParams[0]
            git stash apply "stash@{$index}"
          } else {
            git stash apply
          }
        }
        'drop' {
          if ($subParams) {
            $index = $subParams[0]
            git stash drop "stash@{$index}"
          } else {
            Write-Host "Usage: g st drop <index>" -ForegroundColor Yellow
            Write-Host "Example: g st drop 0" -ForegroundColor Gray
          }
        }
        'clear' {
          Write-Host "This will delete ALL stashes. Are you sure? (y/N)" -ForegroundColor Yellow
          $confirm = Read-Host
          if ($confirm -eq 'y' -or $confirm -eq 'Y') {
            git stash clear
            Write-Host "✅ Cleared all stashes" -ForegroundColor Green
          } else {
            Write-Host "Cancelled" -ForegroundColor Yellow
          }
        }
        default {
          git stash $subCmd $subParams
        }
      }
    }
    # fetch
    'f' { git fetch $Parameters }
    # init
    'i' { git init $Parameters }
    # log
    'l' { git log $Parameters }
    # pretty log
    'll' { git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit }
    # merge
    'm' { git merge $Parameters }
    # pull
    'pl' { git pull $Parameters }
    'plr' { git pull --prune $Parameters }
    # push
    'ps' { git push $Parameters }
    'psu' { git push -u origin HEAD }
    # rebase
    'r' { git rebase $Parameters }
    # reset changes
    'rs' { git reset $Parameters }
    # remote 
    'rt' { git remote $Parameters }
    # status
    's' { git status $Parameters }
    # tag
    't' { git tag $Parameters }
    # catchall
    default { git $Command $Parameters }
  }
}

# ================================================================
# HELP FUNCTION
# ================================================================

function Show-GitHelp {
  Write-Host "  GIT SHORTCUTS (g)" -ForegroundColor Green
  Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
  Write-Host "  Get Help: help git  OR  g help  OR  g h" -ForegroundColor Gray
  Write-Host ""
  Write-Host "🔧 BASIC GIT COMMANDS" -ForegroundColor Yellow
  Write-Host "   g <cmd>                  Git command shortcuts:"
  Write-Host "     a      = add           f      = fetch         m      = merge"
  Write-Host "     b      = branch        i      = init          pl     = pull"
  Write-Host "     c      = checkout      l      = log           plr    = push --prune"
  Write-Host "     cl     = clone         ll     = pretty log    ps     = push"
  Write-Host "     co     = commit        rs     = reset         psu    = push -u origin HEAD"
  Write-Host "     cm     = add + commit (with message).         r      = rebase"
  Write-Host "     cp     = add + commit + push (with message).  s      = status"
  Write-Host "     amend  = amend last commit (optional new message)"
  Write-Host "     t      = tag"
  Write-Host ""
  Write-Host "🌿 BRANCH MANAGEMENT" -ForegroundColor Yellow
  Write-Host "   g br <cmd>               Branch operations:"
  Write-Host "     g br                 list branches with info"
  Write-Host "     g br new <name>      create branch (supports feature/, fix/, chore/)"
  Write-Host "     g br del <name>      safe delete (checks if merged)"
  Write-Host "     g br Del <name>      force delete (capital D)"
  Write-Host "     g br clean           delete all merged branches"
  Write-Host "     g br rename <new>    rename current branch"
  Write-Host ""
  Write-Host "📦 STASH OPERATIONS" -ForegroundColor Yellow
  Write-Host "   g st <cmd>               Stash operations:"
  Write-Host "     g st                 stash with timestamp"
  Write-Host "     g st 'msg'           stash with custom message"
  Write-Host "     g st list            list all stashes"
  Write-Host "     g st show [n]        show stash contents"
  Write-Host "     g st pop             apply and remove latest stash"
  Write-Host "     g st drop <n>        drop stash by index"
  Write-Host ""
  Write-Host "💡 EXAMPLES" -ForegroundColor Yellow
  Write-Host "   g s                      git status"
  Write-Host "   g a .                    git add ."
  Write-Host "   g cm 'Add feature'       Stage all and commit"
  Write-Host "   g cp 'Fix bug'           Stage, commit, and push"
  Write-Host "   g amend                  Amend without changing message"
  Write-Host "   g br                     List branches sorted by date"
  Write-Host "   g br new feature/auth    Create feature/auth and switch to it"
  Write-Host "   g br clean               Delete merged branches"
  Write-Host "   g st 'WIP'               Stash with message"
  Write-Host "   g st pop                 Apply latest stash"
  Write-Host ""
}
