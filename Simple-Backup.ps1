Write-Host "=== Creating Database Backup ===" -ForegroundColor Green

$ServerInstance = "(LocalDb)\MSSQLLocalDB"
$DatabaseName = "aspnet-Connect2Us.2-master-20231127012345"
$BackupPath = ".\App_Data"

# Create backup directory
if (!(Test-Path $BackupPath)) {
    New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
}

# Generate backup filename
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFile = "$BackupPath\DatabaseBackup_${timestamp}.bak"

Write-Host "Creating backup: $backupFile" -ForegroundColor Cyan

# Execute backup
sqlcmd -S "$ServerInstance" -Q "BACKUP DATABASE [$DatabaseName] TO DISK = '$backupFile' WITH FORMAT, NAME = '$DatabaseName-Full Database Backup', SKIP, STATS = 10"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Database backup created successfully!" -ForegroundColor Green
    Write-Host "📁 Backup location: $backupFile" -ForegroundColor Cyan
} else {
    Write-Host "❌ Database backup failed!" -ForegroundColor Red
}

Write-Host "=== Backup Complete ===" -ForegroundColor Green