#requires -Version 5.1
[CmdletBinding()]
param(
    [ValidatePattern('^[vV]?\d+\.\d+\.\d+$')]
    [string]$ClientVersion = '1.5.0',
    [ValidateRange(1, 65535)]
    [int]$BuildNumber = 1,
    [string]$InstanceUrl = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($env:OS -ne 'Windows_NT') {
    throw 'Build on Windows with Visual Studio Desktop development with C++ installed.'
}
if (-not [Environment]::Is64BitProcess) {
    throw 'Run this script in 64-bit PowerShell.'
}
$nativeArchitecture = $env:PROCESSOR_ARCHITECTURE
if ($env:PROCESSOR_ARCHITEW6432) { $nativeArchitecture = $env:PROCESSOR_ARCHITEW6432 }
if ($nativeArchitecture -ne 'AMD64') {
    throw 'This script packages Windows x64 builds; run it on an x64 Windows host.'
}
if ($InstanceUrl) {
    $uri = $null
    if (-not [Uri]::TryCreate($InstanceUrl, [UriKind]::Absolute, [ref]$uri) -or
        $uri.Scheme -notin @('http', 'https')) {
        throw 'InstanceUrl must be an absolute HTTP(S) URL.'
    }
}

$repo = Split-Path -Parent $PSScriptRoot
$flutter = (Get-Command flutter -ErrorAction Stop).Source
function Invoke-Flutter {
    & $flutter @args
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter failed (exit $LASTEXITCODE): $args"
    }
}

Push-Location $repo
try {
    # Match the SDK used by Dockerfile and docker/release.Dockerfile.
    $requiredFlutter = '3.47.7'
    $versionJson = & $flutter --version --machine
    if ($LASTEXITCODE -ne 0) { throw 'Unable to determine Flutter version.' }
    $version = ($versionJson -join "`n") | ConvertFrom-Json
    if ($version.frameworkVersion -ne $requiredFlutter) {
        throw "Flutter $requiredFlutter is required; found $($version.frameworkVersion). See README.md."
    }

    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    if (-not (Test-Path -LiteralPath $vswhere)) {
        throw 'Visual Studio Installer was not found. See the Windows setup in README.md.'
    }
    $visualStudio = & $vswhere -latest -products '*' -requires `
        Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
        Microsoft.VisualStudio.Component.VC.CMake.Project -property installationPath
    if ($LASTEXITCODE -ne 0 -or -not $visualStudio) {
        throw 'Install Desktop development with C++, including MSVC, Windows SDK and CMake.'
    }

    Invoke-Flutter config --enable-windows-desktop
    Invoke-Flutter doctor -v
    # Preserve the committed dependency versions and verify package checksums.
    # This also regenerates Windows plugin registration and symbolic links.
    Invoke-Flutter pub get --enforce-lockfile
    $buildName = $ClientVersion -replace '^[vV]', ''
    # Flutter 3.47.7 selects the Windows target architecture from the host.
    Invoke-Flutter build windows --release --no-pub `
        "--build-name=$buildName" "--build-number=$BuildNumber" `
        "--dart-define=CLIENT_VERSION=$ClientVersion" "--dart-define=INSTANCE_URL=$InstanceUrl"

    $bundle = Join-Path $repo 'build\windows\x64\runner\Release'
    foreach ($file in @('pepeunit_client.exe', 'flutter_windows.dll',
            'msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll',
            'data\app.so', 'data\icudtl.dat', 'data\flutter_assets')) {
        if (-not (Test-Path -LiteralPath (Join-Path $bundle $file))) {
            throw "Incomplete Windows bundle: missing $file."
        }
    }
    $releaseDir = Join-Path $repo 'build\release'
    New-Item -ItemType Directory -Path $releaseDir -Force | Out-Null
    $archive = Join-Path $releaseDir "pepeunit-$ClientVersion-windows-amd64.zip"
    # Archive the whole bundle, including plugin DLLs and native assets.
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $temporaryArchive = Join-Path $releaseDir "$([Guid]::NewGuid()).zip"
    try {
        [IO.Compression.ZipFile]::CreateFromDirectory($bundle, $temporaryArchive)
        Move-Item -LiteralPath $temporaryArchive -Destination $archive -Force
    } finally {
        if (Test-Path -LiteralPath $temporaryArchive) {
            Remove-Item -LiteralPath $temporaryArchive
        }
    }
    $hash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
    "$hash  $(Split-Path -Leaf $archive)" | Set-Content -LiteralPath "$archive.sha256" -Encoding ASCII
    Write-Host "Built: $archive"
    Write-Host "Run: $(Join-Path $bundle 'pepeunit_client.exe')"
} finally {
    Pop-Location
}
