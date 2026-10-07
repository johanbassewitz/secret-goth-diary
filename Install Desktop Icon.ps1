param([switch]$FolderOnly)
$ErrorActionPreference = 'Stop'
try {
    $diary = Join-Path $PSScriptRoot 'index.html'
    $icon = Join-Path $PSScriptRoot 'assets\desktop-icon.ico'
    if (!(Test-Path -LiteralPath $diary) -or !(Test-Path -LiteralPath $icon)) {
        throw 'Keep this installer in the goth diary folder with index.html and assets.'
    }
    $edgePaths = @(
        "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
        "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
        "$env:LOCALAPPDATA\Microsoft\Edge\Application\msedge.exe"
    )
    $edge = $edgePaths | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if (!$edge) { throw 'Microsoft Edge is required to open the diary in its own app window.' }
    $destination = if ($FolderOnly) { $PSScriptRoot } else { [Environment]::GetFolderPath('Desktop') }
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut((Join-Path $destination 'Secret Goth Diary.lnk'))
    $shortcut.TargetPath = $edge
    $diaryUrl = ([System.Uri]$diary).AbsoluteUri
    $shortcut.Arguments = '--app="' + $diaryUrl + '"'
    $shortcut.WorkingDirectory = $PSScriptRoot
    $shortcut.IconLocation = "$icon,0"
    $shortcut.Description = 'Open Secret Goth Diary in its own app window'
    $shortcut.Save()
    Write-Host "Secret Goth Diary app shortcut saved to $destination."
} catch {
    Write-Error $_
    exit 1
}
