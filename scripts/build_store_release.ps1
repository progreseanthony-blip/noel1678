# Build the Android store artifact with production config and the existing upload key.
param([switch]$SkipPreparation)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$appRoot = Join-Path $repoRoot 'apps/main_app'
$logRoot = Join-Path $repoRoot 'scratch'
New-Item -ItemType Directory -Force -Path $logRoot | Out-Null

function Invoke-ReleaseStep([string]$Directory, [string]$Name, [string]$Executable, [string[]]$Arguments) {
    $logFile = Join-Path $logRoot "store_release_$Name.log"
    Write-Host "$Name (log: $logFile)"
    Push-Location $Directory
    try {
        & $Executable @Arguments *> $logFile
        if ($LASTEXITCODE -ne 0) { throw "$Name failed. See $logFile" }
    } finally { Pop-Location }
}

# Never silently create a store artifact signed with the debug key.
$signingFile = Join-Path $appRoot 'android/key.properties'
if (-not (Test-Path -LiteralPath $signingFile)) { throw 'Missing Android upload signing configuration.' }
$signing = @{}
foreach ($line in Get-Content -LiteralPath $signingFile) {
    if ($line -match '^\s*([^#!][^=]*?)\s*=(.*)$') { $signing[$matches[1].Trim()] = $matches[2].Trim() }
}
foreach ($key in 'storeFile', 'storePassword', 'keyAlias', 'keyPassword') {
    if (-not $signing[$key]) { throw "Missing Android signing property: $key" }
}
$keystorePath = [IO.Path]::GetFullPath((Join-Path (Join-Path $appRoot 'android/app') $signing.storeFile))
if (-not (Test-Path -LiteralPath $keystorePath)) { throw 'Android upload keystore not found.' }

$versionLine = Select-String -LiteralPath (Join-Path $appRoot 'pubspec.yaml') -Pattern '^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$'
if (-not $versionLine) { throw 'Expected version: X.Y.Z+N in the app pubspec.' }
$versionName = $versionLine.Matches[0].Groups[1].Value
$buildNumber = $versionLine.Matches[0].Groups[2].Value

if (-not $SkipPreparation) {
    Invoke-ReleaseStep $repoRoot 'root_pub' 'dart' @('pub', 'get')
    foreach ($package in 'packages/core', 'packages/data', 'packages/ui_components', 'apps/main_app') {
        Invoke-ReleaseStep (Join-Path $repoRoot $package) ('pub_' + $package.Replace('/', '_')) 'flutter' @('pub', 'get')
    }
    foreach ($package in 'packages/core', 'packages/data', 'apps/main_app') {
        Invoke-ReleaseStep (Join-Path $repoRoot $package) ('gen_' + $package.Replace('/', '_')) 'dart' @('run', 'build_runner', 'build', '--delete-conflicting-outputs')
    }
}

$config = @{}
foreach ($line in Get-Content -LiteralPath (Join-Path $repoRoot '.env.production')) {
    if ($line.Trim() -match '^(ENVIRONMENT|SUPABASE_URL|SUPABASE_ANON_KEY)\s*=(.*)$') {
        $config[$matches[1]] = $matches[2].Trim().Trim('"').Trim("'")
    }
}
foreach ($key in 'ENVIRONMENT', 'SUPABASE_URL', 'SUPABASE_ANON_KEY') {
    if (-not $config[$key]) { throw "Missing production config: $key" }
}
if ($config.ENVIRONMENT -ne 'production' -or -not $config.SUPABASE_URL.StartsWith('https://')) {
    throw 'Expected production environment with an HTTPS Supabase URL.'
}
$configDir = Join-Path $appRoot '.dart_tool/stores'
New-Item -ItemType Directory -Force -Path $configDir | Out-Null
$config | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $configDir 'production.json') -Encoding utf8

Invoke-ReleaseStep $appRoot 'android_bundle' 'flutter' @('build', 'appbundle', '--release', '--no-pub', "--build-name=$versionName", "--build-number=$buildNumber", '--dart-define-from-file=.dart_tool/stores/production.json')
$bundle = Join-Path $appRoot 'build/app/outputs/bundle/release/app-release.aab'
if (-not (Test-Path -LiteralPath $bundle)) { throw 'Android bundle was not generated.' }
$jarsignerCommand = Get-Command 'jarsigner' -ErrorAction SilentlyContinue
if (-not $jarsignerCommand) { throw 'jarsigner must be available to verify the Android upload signature.' }
Invoke-ReleaseStep $appRoot 'android_signature' $jarsignerCommand.Source @('-J-Duser.language=en', '-J-Duser.country=US', '-verify', $bundle)
if (-not (Select-String -LiteralPath (Join-Path $logRoot 'store_release_android_signature.log') -Pattern 'jar verified\.')) {
    throw 'Android bundle signature could not be verified.'
}
$releaseDir = Join-Path $repoRoot 'releases/android'
New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null
$outputFile = Join-Path $releaseDir "global-golf-$versionName-build$buildNumber.aab"
Copy-Item -LiteralPath $bundle -Destination $outputFile
$hash = (Get-FileHash -LiteralPath $outputFile -Algorithm SHA256).Hash
"$hash  $([IO.Path]::GetFileName($outputFile))" | Set-Content -LiteralPath "$outputFile.sha256"
Write-Host "Android release $versionName+$buildNumber ready: $outputFile"
