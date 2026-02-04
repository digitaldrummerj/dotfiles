# Justin's (digitaldrummerj) PowerShell Setup

> This profile is setup for Mac and has not been tested on Windows

## Prerequisites

1. **PowerShell 7+** - Install from [Microsoft's website](https://github.com/PowerShell/PowerShell) or via Homebrew:

   ```bash
   brew install --cask powershell
   ```

   1. Open Terminal
   1. Go to Settings
   1. Click on Profiles
   1. Click the + to add a new Profile
   1. Name the profile Powershell
   1. Go to the Shell tab for the Powershell profile
       - check the 'Run command' and put in `/usr/local/microsoft/powershell/7/pwsh`

1. **Powershell Modules** - for Auto Complete previous commands and terminal icons with ls

    ```bash
    Install-Module PSReadLine
    Install-Module Terminal-Icons
    ```

1. **Oh My Posh** - Better Terminal Prompt

    ```bash
    brew install oh-my-posh
    ```

1. **Fonts** - Monaspace Nerd Font so you get icons in the terminal

    ```bash
    brew install --cask font-monaspice-nerd-font
    ```

   💡 After installing, set terminal font to: MonaspiceKr Nerd Font Mono (Terminal → Settings → Text → Change Font)

## Installation Steps

### 1. Download files

1. Download the Gist Zip file
1. Unzip the file
1. Open your Powershell Terminal
1. Navigate to the zip file directory
1. Run `./install.ps1` to copy the file to your Powershell profile directory.  It will backup your existing files in your profile directory.

### 1. Set Up GitHub Gist Token (Required for Sync)

The profile uses GitHub Gist for syncing across machines. You'll need a personal access token:

1. Go to [GitHub Settings → Tokens](https://github.com/settings/tokens)
2. Generate a new token with `gist` scope
3. Store it securely in macOS Keychain:

   ```powershell
   # From PowerShell, run:
   SetEnv 'GITHUB_GIST_TOKEN' 'your-token-here'
   ```

### 2. Update Gist ID (For Your Own Gist)

1. Go to [https://gist.github.com/](https://gist.github.com/) and create a public gist to hold your profile files
1. Edit `~/.config/powershell/modules/config.ps1` and update the gist ID to your own:

```powershell
$script:GistId = "your-gist-id-here"
```

Set Up GitHub Private Gist Id (Required for Sync) to hold your Powershell modules that you want to keep private

1. Go to [https://gist.github.com/](https://gist.github.com/) and create a secret gist
1. Grab the Gist Id
1. Set the Environment Variable

   ```powershell
   # From PowerShell, run:
   SetEnv 'POWERSHELL_PRIVATE_GIST_ID' 'your-gist-id-here'
   ```

### 4. Sync to Your Own Gist

Sync from Profile to Gist

```powershell
profile ps    # Push to your gist
```

Sync from Gist to Profile:

```powershell
profile pl    # Pull from your gist
```

## Enjoy! 🎉

Type `help` in your terminal to see all available shortcuts and features.

---
