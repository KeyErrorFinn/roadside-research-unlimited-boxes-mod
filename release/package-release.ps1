$ErrorActionPreference = 'Stop'
$releaseRoot = $PSScriptRoot
$projectRoot = Split-Path $releaseRoot -Parent
$manifest = Get-Content -LiteralPath (Join-Path $releaseRoot 'manifest.json') -Raw | ConvertFrom-Json
if ($manifest.name -notmatch '^[A-Za-z0-9_]+$' -or $manifest.version_number -notmatch '^\d+\.\d+\.\d+$') { throw 'Invalid package name or version.' }
if ($manifest.description.Length -gt 250 -or !$manifest.description) { throw 'Description must contain 1-250 characters.' }
foreach ($file in @('manifest.json', 'README.md', 'CHANGELOG.md', 'icon.png')) {
    if (!(Test-Path -LiteralPath (Join-Path $releaseRoot $file) -PathType Leaf)) { throw "Missing $file" }
}
Add-Type -AssemblyName System.Drawing
$icon = [System.Drawing.Image]::FromFile((Join-Path $releaseRoot 'icon.png'))
try {
    if ($icon.Width -ne 256 -or $icon.Height -ne 256 -or $icon.RawFormat.Guid -ne [System.Drawing.Imaging.ImageFormat]::Png.Guid) { throw 'icon.png must be a 256x256 PNG.' }
} finally { $icon.Dispose() }
$project = [xml](Get-Content -LiteralPath (Join-Path $projectRoot 'UnlimitedBoxes.csproj') -Raw)
if ([string]$project.Project.PropertyGroup.Version -ne $manifest.version_number) { throw 'Project and manifest versions differ.' }
& (Join-Path $projectRoot 'build.ps1') -BuildOnly
if ($LASTEXITCODE -ne 0) { throw 'Build failed.' }
$dll = Join-Path $projectRoot 'bin\Release\net6.0\KeyErrorFinn.UnlimitedBoxes.dll'
$dllVersion = [Diagnostics.FileVersionInfo]::GetVersionInfo($dll).FileVersion
if ($dllVersion -ne "$($manifest.version_number).0") { throw 'DLL version differs from manifest.' }
$zipPath = Join-Path $projectRoot "dist\$($manifest.name)-$($manifest.version_number).zip"
New-Item -ItemType Directory -Force (Split-Path $zipPath -Parent) | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.IO.Compression
$files = [ordered]@{}
foreach ($file in @('manifest.json', 'README.md', 'CHANGELOG.md', 'icon.png')) { $files[$file] = Join-Path $releaseRoot $file }
$files['BepInEx/plugins/KeyErrorFinn-UnlimitedBoxes/KeyErrorFinn.UnlimitedBoxes.dll'] = $dll
$stream = [IO.File]::Open($zipPath, [IO.FileMode]::Create)
$zip = New-Object IO.Compression.ZipArchive($stream, [IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($entry in $files.GetEnumerator()) {
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $entry.Value, $entry.Key, [IO.Compression.CompressionLevel]::Optimal) | Out-Null
    }
} finally { $zip.Dispose(); $stream.Dispose() }
$zip = [IO.Compression.ZipFile]::OpenRead($zipPath)
try {
    $names = @($zip.Entries | ForEach-Object FullName)
    if ($names.Count -ne $files.Count) { throw 'Unexpected ZIP entry count.' }
    foreach ($name in $files.Keys) {
        $entry = $zip.GetEntry($name)
        if (!$entry) { throw "Missing ZIP entry: $name" }
        $source = [IO.File]::OpenRead($files[$name])
        $packed = $entry.Open()
        $sha = [Security.Cryptography.SHA256]::Create()
        try {
            $expected = [Convert]::ToBase64String($sha.ComputeHash($source))
            $actual = [Convert]::ToBase64String($sha.ComputeHash($packed))
            if ($expected -ne $actual) { throw "ZIP integrity mismatch: $name" }
        } finally { $source.Dispose(); $packed.Dispose(); $sha.Dispose() }
    }
} finally { $zip.Dispose() }
Write-Output "Validated Thunderstore upload: $zipPath"
Get-FileHash -LiteralPath $zipPath -Algorithm SHA256
