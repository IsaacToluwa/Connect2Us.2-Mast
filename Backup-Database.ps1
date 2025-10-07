# Database Backup Utility for Connect2Us
# This script creates backups of the LocalDB database

param(
    [string]$BackupPath = "C:\Users\olatu\source\repos\Connect2Us.2-master\App_Data\Backups",
    [string]$DatabaseName = "aspnet-Connect2Us.2-master-20231127012345",
    [string]$ServerInstance = "(LocalDb)\MSSQLLocalDB",
    [string]$BackupName = "Connect2Us_Database",
    [switch]$Compress = $false,
    [switch]$Verify = $true,
    [switch]$CleanupOld = $true,
    [int]$KeepBackups = 5
)

# Create backup directory if it doesn't exist
if (-not (Test-Path $BackupPath)) {
    New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
    Write-Host "Created backup directory: $BackupPath" -ForegroundColor Green
}

Write-Host "=== Connect2Us Database Backup Utility ===" -ForegroundColor Green
Write-Host "Database: $DatabaseName" -ForegroundColor Yellow
Write-Host "Server: $ServerInstance" -ForegroundColor Yellow
Write-Host "Backup Path: $BackupPath" -ForegroundColor Yellow
Write-Host ""

# Generate timestamped backup filename
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFile = "$BackupPath\$BackupName`_$timestamp.bak"

Write-Host "Creating database backup..." -ForegroundColor Cyan
Write-Host "Backup file: $backupFile" -ForegroundColor Gray

try {
    # Create the backup
    $backupQuery = @"
BACKUP DATABASE [$DatabaseName] 
TO DISK = '$backupFile' 
WITH FORMAT, 
     INIT, 
     NAME = '$DatabaseName-Full Database Backup', 
     SKIP, 
     NOREWIND, 
     NOUNLOAD, 
     STATS = 10
"@
    
    Write-Host "Executing backup command..." -ForegroundColor Yellow
    sqlcmd -S "$ServerInstance" -Q $backupQuery
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Database backup created successfully!" -ForegroundColor Green
        
        # Get backup file info
        if (Test-Path $backupFile) {
            $fileInfo = Get-Item $backupFile
            $fileSizeMB = [math]::Round($fileInfo.Length / 1MB, 2)
            Write-Host "📊 Backup size: $fileSizeMB MB" -ForegroundColor Cyan
            
            # Verify backup if requested
            if ($Verify) {
                Write-Host "Verifying backup integrity..." -ForegroundColor Yellow
                
                $verifyQuery = "RESTORE VERIFYONLY FROM DISK = '$backupFile'"
                sqlcmd -S "$ServerInstance" -Q $verifyQuery
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "✅ Backup verification successful!" -ForegroundColor Green
                } else {
                    Write-Host "⚠️  Backup verification failed!" -ForegroundColor Red
                }
            }
            
            # Compress backup if requested
            if ($Compress) {
                Write-Host "Compressing backup..." -ForegroundColor Yellow
                
                try {
                    Compress-Archive -Path $backupFile -DestinationPath "$backupFile.zip" -CompressionLevel Optimal
                    $compressedInfo = Get-Item "$backupFile.zip"
                    $compressedSizeMB = [math]::Round($compressedInfo.Length / 1MB, 2)
                    $compressionRatio = [math]::Round((($fileInfo.Length - $compressedInfo.Length) / $fileInfo.Length) * 100, 1)
                    
                    Write-Host "✅ Backup compressed successfully!" -ForegroundColor Green
                    Write-Host "📊 Compressed size: $compressedSizeMB MB (saved $compressionRatio%)" -ForegroundColor Cyan
                    
                    # Remove original backup file
                    Remove-Item $backupFile -Force
                    $backupFile = "$backupFile.zip"
                }
                catch {
                    Write-Host "⚠️  Compression failed: $_" -ForegroundColor Red
                }
            }
            
            # Clean up old backups if requested
            if ($CleanupOld) {
                Write-Host "Cleaning up old backups..." -ForegroundColor Yellow
                
                $backupFiles = Get-ChildItem -Path $BackupPath -Name "$BackupName*.bak*" -File | Sort-Object LastWriteTime -Descending
                
                if ($backupFiles.Count -gt $KeepBackups) {
                    $filesToRemove = $backupFiles | Select-Object -Skip $KeepBackups
                    
                    foreach ($file in $filesToRemove) {
                        $fullPath = Join-Path $BackupPath $file
                        Write-Host "Removing old backup: $file" -ForegroundColor Gray
                        Remove-Item $fullPath -Force
                    }
                    
                    Write-Host "✅ Cleaned up $($filesToRemove.Count) old backup(s)" -ForegroundColor Green
                } else {
                    Write-Host "No old backups to clean up" -ForegroundColor Gray
                }
            }
            
            Write-Host ""
            Write-Host "=== Backup Summary ===" -ForegroundColor Green
            Write-Host "✅ Backup completed successfully!" -ForegroundColor Green
            Write-Host "📁 Backup file: $backupFile" -ForegroundColor Cyan
            Write-Host "📊 File size: $fileSizeMB MB" -ForegroundColor Cyan
            Write-Host "🕐 Created at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
            
            # Show restore command
            if ($backupFile.EndsWith('.bak')) {
                Write-Host ""
                Write-Host "To restore this backup, use:" -ForegroundColor Yellow
                Write-Host "sqlcmd -S `"$ServerInstance`" -Q `"RESTORE DATABASE [$DatabaseName] FROM DISK = '$backupFile' WITH REPLACE`"" -ForegroundColor Gray
            }
            
            return $backupFile
        } else {
            Write-Host "❌ Backup file not found!" -ForegroundColor Red
            return $null
        }
    } else {
        Write-Host "❌ Database backup failed!" -ForegroundColor Red
        return $null
    }
}
catch {
    Write-Host "❌ Error during backup: $_" -ForegroundColor Red
    return $null
}

Write-Host ""
Write-Host "=== Backup Operation Complete ===" -ForegroundColor Green