# Simple Database Backup Script
param(
    [string]$ServerInstance = "(LocalDb)\MSSQLLocalDB",
    [string]$DatabaseName = "aspnet-Connect2Us.2-master-20231127012345",
    [string]$BackupPath = ".\App_Data"
)

Write-Host "=== Creating Database Backup ===" -ForegroundColor Green
Write-Host "Database: $DatabaseName" -ForegroundColor Yellow
Write-Host "Server: $ServerInstance" -ForegroundColor Yellow
Write-Host ""

# Create backup directory if it doesn't exist
if (!(Test-Path $BackupPath)) {
    New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
    Write-Host "Created backup directory: $BackupPath" -ForegroundColor Gray
}

# Generate backup filename with timestamp
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFile = "$BackupPath\DatabaseBackup_${timestamp}.bak"

Write-Host "Creating backup: $backupFile" -ForegroundColor Cyan

# Execute backup command
$backupQuery = "BACKUP DATABASE [$DatabaseName] TO DISK = '$backupFile' WITH FORMAT, NAME = '$DatabaseName-Full Database Backup', SKIP, NOREWIND, NOUNLOAD, STATS = 10"

sqlcmd -S "$ServerInstance" -Q $backupQuery

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Database backup created successfully!" -ForegroundColor Green
    Write-Host "📁 Backup location: $backupFile" -ForegroundColor Cyan
    
    # Show file size
    if (Test-Path $backupFile) {
        $fileSize = (Get-Item $backupFile).Length / 1MB
        Write-Host "📊 Backup size: $([math]::Round($fileSize, 2)) MB" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "💡 To restore this backup, use:" -ForegroundColor Yellow
    Write-Host "sqlcmd -S \"$ServerInstance\" -Q \"RESTORE DATABASE [$DatabaseName] FROM DISK = '$backupFile'\"" -ForegroundColor Gray
    
} else {
    Write-Host "❌ Database backup failed!" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Backup Process Complete ===" -ForegroundColor Green