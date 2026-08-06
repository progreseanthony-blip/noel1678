param(
    [string]$Container = "supabase_db_Noel_1678",
    [string]$BackupDir = "$PSScriptRoot/../backups"
)

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupDir = Resolve-Path $backupDir
$outputFile = "$backupDir/data_backup_$timestamp.sql"

Write-Host "=== Respaldo de Base de Datos ===" -ForegroundColor Cyan
Write-Host "Container: $Container" -ForegroundColor Gray
Write-Host "Destino: $outputFile" -ForegroundColor Gray

# Ensure backup dir exists
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

# Dump using docker exec pg_dump (internal container port 5432)
$result = docker exec -i $Container pg_dump `
    "--data-only" "--inserts" "--attribute-inserts" "--no-owner" "--no-acl" `
    "--dbname=postgresql://postgres:postgres@127.0.0.1:5432/postgres" 2>&1

if ($LASTEXITCODE -eq 0) {
    $result | Set-Content -Path $outputFile -Encoding utf8
    $size = (Get-Item $outputFile).Length
    Write-Host "OK: Respaldo creado ($size bytes)" -ForegroundColor Green
} else {
    Write-Error "ERROR: pg_dump falló (exit code $LASTEXITCODE)"
    Write-Host $result -ForegroundColor Red
    exit 1
}
