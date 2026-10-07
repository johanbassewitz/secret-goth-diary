param([string]$InstallerPath, [string]$ArchivePath)
$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
$installer = if ($InstallerPath) { $InstallerPath } else { Join-Path $project 'packaging\Install.ps1' }
if (!(Test-Path -LiteralPath $installer)) { throw 'Installer is missing: installation must copy the diary off the desktop and create an app shortcut.' }
$testRoot = Join-Path $project ('.installer-test-' + [Guid]::NewGuid().ToString('N'))
$fixture = Join-Path $testRoot 'payload'
$destination = Join-Path $testRoot 'Local AppData\Secret Goth Diary'
$desktop = Join-Path $testRoot 'Desktop'
New-Item -ItemType Directory -Path $fixture,$desktop -Force | Out-Null
foreach ($item in @('index.html','css','js','assets','sw.js')) {
    Copy-Item -LiteralPath (Join-Path $project $item) -Destination $fixture -Recurse
}
$zip = Join-Path $testRoot 'diary.zip'
if ($ArchivePath) { Copy-Item -LiteralPath $ArchivePath -Destination $zip } else { Compress-Archive -Path (Join-Path $fixture '*') -DestinationPath $zip }
Set-Content -LiteralPath (Join-Path $desktop 'unrelated.txt') -Value 'keep me'
& $installer -PayloadPath $zip -InstallDirectory $destination -DesktopDirectory $desktop -Quiet -NoLaunch
if (!(Test-Path -LiteralPath (Join-Path $destination 'index.html'))) { throw 'Diary was not installed into AppData.' }
if (!(Test-Path -LiteralPath (Join-Path $destination 'css\fonts.css'))) { throw 'Offline fonts missing.' }
$items = @(Get-ChildItem -LiteralPath $desktop)
if ($items.Count -ne 2 -or @(Get-ChildItem -LiteralPath $desktop -Directory).Count -ne 0) { throw 'Installer added extra desktop files or a folder.' }
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut((Join-Path $desktop 'Secret Goth Diary.lnk'))
if ($shortcut.TargetPath -notlike '*\msedge.exe') { throw 'Shortcut opens a browser tab instead of app mode.' }
if (!$shortcut.Arguments.StartsWith('--app="file:///')) { throw 'Shortcut does not launch the local diary in app mode.' }
if ($shortcut.Arguments -notlike '*Local%20AppData/Secret%20Goth%20Diary/index.html*') { throw 'Shortcut points to the download folder instead of the installed diary.' }
if ($shortcut.IconLocation -notlike '*desktop-icon.ico,0') { throw 'Showcase icon is missing.' }
Set-Content -LiteralPath (Join-Path $destination 'keep.txt') -Value 'existing user file'
& $installer -PayloadPath $zip -InstallDirectory $destination -DesktopDirectory $desktop -Quiet -NoLaunch
if ((Get-Content -LiteralPath (Join-Path $destination 'keep.txt')) -ne 'existing user file') { throw 'Reinstall removed user files.' }
if ((Get-Content -LiteralPath (Join-Path $desktop 'unrelated.txt')) -ne 'keep me') { throw 'Installer changed unrelated desktop files.' }
Write-Output 'PASS: install outside desktop, one app shortcut, offline assets, encoded paths, safe reinstall.'
Write-Output "Test installation retained at $testRoot"
