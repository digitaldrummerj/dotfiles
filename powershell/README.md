# Justin's (digitaldrummerj) PowerShell Setup

> This profile is setup for Mac and has not been tested on Windows

## 🚀 Quick Install (End Users - From Gist)

**For a brand new machine, use the automated gist installer:**

1. Download the gist and run the install.ps1

The installer will:

- ✅ Create the proper directory structure (`~/.config/powershell/`)
- ✅ Download all files from gist
- ✅ Set proper permissions on scripts
- ✅ Check for required dependencies
- ✅ Provide next steps for environment setup

**After installation:**

1. Close and reopen your terminal
2. Set required environment variables (see Configuration section)
3. Type `help` to see all available commands

---

## 👨‍💻 Developer Setup (From Git Repository)

**For development work, clone the full repository:**

```bash
git clone --recurse-submodules https://github.com/digitaldrummerj/dotfiles.git
cd dotfiles/powershell
```

This gives you:

- Full Git history for version control
- Access to private modules (submodule)
- Ability to make changes and submit PRs

## Prerequisites

1. **PowerShell 7+** - Install from [Microsoft's website](https://github.com/PowerShell/PowerShell) or via Homebrew:

   ```bash
   brew install --cask powershell
   ```

2. **Homebrew** - Required for dependency management (if not already installed):

   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

## Installation Steps

### 1. Set Up GitHub Gist Token (Required for Sync)

The profile uses GitHub Gist for syncing across machines. You'll need a personal access token:

1. Go to [GitHub Settings → Tokens](https://github.com/settings/tokens)
2. Generate a new token with `gist` scope
3. Store it securely in macOS Keychain:

   ```powershell
   # From PowerShell, run:
   SetEnv 'GITHUB_GIST_TOKEN' 'your-token-here'
   ```

### 3. Update Gist ID (For Your Own Gist)

Edit `~/.config/powershell/modules/config.ps1` and update the gist ID to your own:

```powershell
$script:GistId = "your-gist-id-here"
```

### 4. Install Dependencies

The profile will automatically check for missing dependencies on first run and show install commands:

- **PSReadLine** - Enhanced command-line editing
- **Terminal-Icons** - Pretty icons for files/folders  
- **Oh-My-Posh** - Prompt theming engine
- **Monaspace Nerd Font** - Required font for icons

When you first load the profile, it will show something like:

```text
⚠️  Missing dependencies:
   • PSReadLine - Install with: Install-Module PSReadLine
   • Terminal-Icons - Install with: Install-Module Terminal-Icons
   • Oh-My-Posh - Install with: brew install oh-my-posh
   • Monaspace Nerd Font - Install with: brew install --cask font-monaspice-nerd-font
   
   💡 After installing, set terminal font to: MonaspiceKr Nerd Font
      (Terminal → Settings → Text → Change Font)
```

Just copy and paste the install commands shown.

### 5. Configure Your Terminal Font

After installing the Nerd Font, configure your terminal:

1. Open Terminal preferences
2. Go to your profile → Text tab
3. Click "Change" button next to Font
4. Select "MonaspiceKr Nerd Font" (or your preferred Monaspace variant)
5. Restart Terminal

### 6. Sync to Your Own Gist (Optional)

Once everything is set up, you can push your profile to your own gist:

```powershell
profile ps    # Push to your gist
```

On other machines, you can pull it down with:

```powershell
profile pl    # Pull from your gist
```

## Enjoy! 🎉

Type `help` in your terminal to see all available shortcuts and features.

---
