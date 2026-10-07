$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
$dist = Join-Path $project 'dist'
$stage = Join-Path $dist ('stage-' + [Guid]::NewGuid().ToString('N'))
$payload = Join-Path $stage 'payload'
New-Item -ItemType Directory -Path $dist,$stage,$payload -Force | Out-Null
# Explicit allowlist: never include local notes, shortcuts, or development files.
foreach ($item in @('index.html','css','js','sw.js')) {
    Copy-Item -LiteralPath (Join-Path $project $item) -Destination $payload -Recurse -Force
}
New-Item -ItemType Directory -Path (Join-Path $payload 'assets') -Force | Out-Null
foreach ($asset in @('icon.ico','icon.png','icon.svg','desktop-icon.ico','manifest.webmanifest')) {
    Copy-Item -LiteralPath (Join-Path $project ('assets\' + $asset)) -Destination (Join-Path $payload 'assets') -Force
}
$archiveFiles = @('index.html','css','js','sw.js','assets') | ForEach-Object { Join-Path $payload $_ }
Compress-Archive -Path $archiveFiles -DestinationPath (Join-Path $stage 'diary.zip') -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Install.ps1') -Destination $stage -Force
$output = Join-Path $dist 'SecretGothDiary-Setup.exe'
$compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (!(Test-Path -LiteralPath $compiler)) { $compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe' }
& $compiler /nologo /target:winexe /platform:anycpu /reference:System.Windows.Forms.dll "/out:$output" "/win32icon:$(Join-Path $project 'assets\desktop-icon.ico')" "/win32manifest:$(Join-Path $PSScriptRoot 'setup.manifest')" "/resource:$(Join-Path $stage 'diary.zip'),diary.zip" "/resource:$(Join-Path $stage 'Install.ps1'),Install.ps1" (Join-Path $PSScriptRoot 'Setup.cs')
if ($LASTEXITCODE -ne 0 -or !(Test-Path -LiteralPath $output)) { throw 'Installer compilation failed.' }
$header = [IO.File]::ReadAllBytes($output)
if ($header[0] -ne 77 -or $header[1] -ne 90) { throw 'Build did not produce a Windows executable.' }
Get-FileHash -LiteralPath $output -Algorithm SHA256 | ForEach-Object {
    Set-Content -LiteralPath (Join-Path $dist 'SHA256SUMS.txt') -Value ($_.Hash.ToLower() + '  SecretGothDiary-Setup.exe') -Encoding ASCII
}
Get-Item -LiteralPath $output | Select-Object FullName,Length

