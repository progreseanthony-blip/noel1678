# run_dev.ps1 — Run the app locally loading config from .env
param(
    [string]$Device = "chrome",
    [string]$Port = "8081"
)

$root = Split-Path -Parent $PSScriptRoot

# Load .env file
$envFile = Join-Path $root ".env"
if (-not (Test-Path $envFile)) {
    Write-Error "ERROR: .env file not found at $envFile"
    exit 1
}

Write-Host "Loading config from .env..." -ForegroundColor Cyan
Get-Content $envFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith("#") -and $line.Contains("=")) {
        $parts = $line.Split("=", 2)
        $key = $parts[0].Trim()
        $value = $parts[1].Trim()
        [Environment]::SetEnvironmentVariable($key, $value, "Process")
        Write-Host "  $key = $value" -ForegroundColor DarkGray
    }
}

Write-Host "Running app on $Device (port $Port)..." -ForegroundColor Cyan
Write-Host "ENVIRONMENT: $env:ENVIRONMENT" -ForegroundColor Green
Write-Host "SUPABASE_URL: $env:SUPABASE_URL" -ForegroundColor Green

Set-Location (Join-Path $root "apps/main_app")

flutter run -d $Device --web-port $Port `
  --dart-define=ENVIRONMENT=$env:ENVIRONMENT `
  --dart-define=SUPABASE_URL=$env:SUPABASE_URL `
  --dart-define=SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY
