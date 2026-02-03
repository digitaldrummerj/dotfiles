# ================================================================
# CONFIGURATION
# ================================================================
# Global variables and paths used throughout the profile

# Public gist - contains modules/, scripts/, profile.ps1, theme, bookmarks
$script:GistId = "caf018f57b9006a00d7aa1866d580e5b"

# Private gist - contains private-modules/ (optional, requires GITHUB_GIST_TOKEN)
# Set via environment variable: POWERSHELL_PRIVATE_GIST_ID
$script:PrivateGistId = $env:POWERSHELL_PRIVATE_GIST_ID

$script:ProfileDir = Split-Path -Parent $PROFILE
$script:themeFileName = "theme.omp.json"
$script:themePath = Join-Path $script:ProfileDir $script:themeFileName
$script:bookmarksFileName = "bookmarks.json"
$script:bookmarksPath = Join-Path $script:ProfileDir $script:bookmarksFileName

# Machine name detection for bookmarks (cross-platform)
$script:machineName = if ($env:MACHINE_NAME) {
    # Custom override (highest priority)
    $env:MACHINE_NAME
} elseif ($IsWindows) {
    # Windows: Use COMPUTERNAME env var
    $env:COMPUTERNAME
} else {
    # Mac: Use hostname command, strip .local suffix
    $hostname = Invoke-Expression -Command 'hostname'
    $hostname -replace '\.local$', ''
}








