param([switch]$SkipReferenceDownload, [switch]$BuildOnly)
$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    $core = Join-Path $PSScriptRoot '.tools\thunderstore-bepinex\BepInExPack\BepInEx\core\BepInEx.Unity.IL2CPP.dll'
    if (!(Test-Path -LiteralPath $core) -and !(Test-Path -LiteralPath 'GameReferences.props')) {
        if ($SkipReferenceDownload) { throw 'Set BepInExDir in GameReferences.props or allow the reference download.' }
        New-Item -ItemType Directory -Force '.tools' | Out-Null
        $url = 'https://thunderstore.io/package/download/BepInEx/BepInExPack_IL2CPP/6.0.788/'
        Invoke-WebRequest $url -OutFile '.tools\thunderstore-bepinex.zip'
        $expected = 'CE25D925F9EABA817214F5D6B2083B8E135ED0592B5A61B9F75EA5D4C02F5300'
        if ((Get-FileHash '.tools\thunderstore-bepinex.zip' -Algorithm SHA256).Hash -ne $expected) {
            throw 'BepInEx reference archive checksum mismatch.'
        }
        Expand-Archive '.tools\thunderstore-bepinex.zip' '.tools\thunderstore-bepinex' -Force
    }
    dotnet build UnlimitedBoxes.csproj -c Release
    if ($LASTEXITCODE -ne 0) { throw 'Build failed.' }
    if ($BuildOnly) { return }
    $package = 'dist\UnlimitedUniversalBoxes-1.0.1'
    New-Item -ItemType Directory -Force "$package\BepInEx\plugins\KeyErrorFinn-UnlimitedBoxes" | Out-Null
    Copy-Item 'bin\Release\net6.0\KeyErrorFinn.UnlimitedBoxes.dll' "$package\BepInEx\plugins\KeyErrorFinn-UnlimitedBoxes\"
    Copy-Item README.md $package
    Compress-Archive "$package\*" 'dist\UnlimitedUniversalBoxes-1.0.1.zip' -Force
    Get-FileHash 'dist\UnlimitedUniversalBoxes-1.0.1.zip' -Algorithm SHA256
}
finally { Pop-Location }

