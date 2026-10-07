param(
    [string]$PayloadPath = (Join-Path $PSScriptRoot 'diary.zip'),
    [string]$InstallDirectory = (Join-Path $env:LOCALAPPDATA 'Programs\Secret Goth Diary'),
    [string]$DesktopDirectory = [Environment]::GetFolderPath('Desktop'),
    [switch]$Quiet,
    [switch]$NoLaunch
)
$ErrorActionPreference = 'Stop'
try {
    $edge = @(
        "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
        "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
        "$env:LOCALAPPDATA\Microsoft\Edge\Application\msedge.exe"
    ) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if (!$edge) { throw 'Microsoft Edge is required. Install Edge, then run setup again.' }
    if (!(Test-Path -LiteralPath $PayloadPath)) { throw 'The diary installation package is missing.' }
    New-Item -ItemType Directory -Path $InstallDirectory -Force | Out-Null
    Expand-Archive -LiteralPath $PayloadPath -DestinationPath $InstallDirectory -Force
    $diary = Join-Path $InstallDirectory 'index.html'
    $icon = Join-Path $InstallDirectory 'assets\desktop-icon.ico'
    if (!(Test-Path -LiteralPath $diary) -or !(Test-Path -LiteralPath $icon)) {
        throw 'The diary installation package is incomplete.'
    }
    New-Item -ItemType Directory -Path $DesktopDirectory -Force | Out-Null
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut((Join-Path $DesktopDirectory 'Secret Goth Diary.lnk'))
    $shortcut.TargetPath = $edge
    $shortcut.Arguments = '--app="' + ([Uri]$diary).AbsoluteUri + '"'
    $shortcut.WorkingDirectory = $InstallDirectory
    $shortcut.IconLocation = "$icon,0"
    $shortcut.Description = 'Open Secret Goth Diary'
    $shortcut.Save()
    if (!$Quiet) {
        Add-Type -AssemblyName System.Windows.Forms
        [void][Windows.Forms.MessageBox]::Show('Your diary is ready. Open Secret Goth Diary from your desktop anytime.', 'Secret Goth Diary', 'OK', 'Information')
    }
    if (!$NoLaunch) { Start-Process -FilePath $edge -ArgumentList $shortcut.Arguments }
} catch {
    if (!$Quiet) {
        Add-Type -AssemblyName System.Windows.Forms
        [void][Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Secret Goth Diary - Setup', 'OK', 'Error')
    }
    throw
}
