# Test Entity Framework Migrations Locally
# This script tests EF migrations and creates database backups

param(
    [string]$ServerInstance = "(LocalDb)\MSSQLLocalDB",
    [string]$DatabaseName = "aspnet-Connect2Us.2-master-20231127012345",
    [string]$BackupPath = ".\App_Data",
    [switch]$SkipBackup = $false,
    [switch]$Verbose = $false
)

# Function to create timestamp
function Get-TimeStamp {
    return Get-Date -Format "yyyyMMdd_HHmmss"
}

# Function to create database backup
function Create-DatabaseBackup {
    param(
        [string]$BackupType = "Manual"
    )
    
    $timestamp = Get-TimeStamp
    $backupFile = "$BackupPath\DatabaseBackup_${BackupType}_${timestamp}.bak"
    
    Write-Host "Creating database backup..." -ForegroundColor Cyan
    Write-Host "Database: $DatabaseName" -ForegroundColor Gray
    Write-Host "Backup file: $backupFile" -ForegroundColor Gray
    
    try {
        # Create backup directory if it doesn't exist
        if (!(Test-Path $BackupPath)) {
            New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
        }
        
        # Execute backup command
        $backupQuery = @"
BACKUP DATABASE [$DatabaseName] 
TO DISK = '$backupFile' 
WITH FORMAT, 
NAME = '$DatabaseName-Full Database Backup', 
SKIP, 
NOREWIND, 
NOUNLOAD, 
STATS = 10
"@
        
        sqlcmd -S "$ServerInstance" -Q $backupQuery
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Database backup created successfully!" -ForegroundColor Green
            Write-Host "📁 Backup location: $backupFile" -ForegroundColor Cyan
            return $backupFile
        } else {
            Write-Host "❌ Database backup failed!" -ForegroundColor Red
            return $null
        }
    }
    catch {
        Write-Host "❌ Error during backup: $_" -ForegroundColor Red
        return $null
    }
}

# Function to test Entity Framework migrations
function Test-EntityFrameworkMigrations {
    Write-Host "Testing Entity Framework migrations..." -ForegroundColor Cyan
    
    try {
        # Navigate to MigrationRunner directory
        Push-Location ".\MigrationRunner"
        
        # Build the MigrationRunner project
        Write-Host "Building MigrationRunner..." -ForegroundColor Gray
        dotnet build --configuration Release
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ MigrationRunner built successfully!" -ForegroundColor Green
            
            # Run the MigrationRunner
            Write-Host "Running MigrationRunner..." -ForegroundColor Gray
            dotnet run --configuration Release
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Entity Framework migrations completed successfully!" -ForegroundColor Green
                return $true
            } else {
                Write-Host "❌ Entity Framework migrations failed!" -ForegroundColor Red
                return $false
            }
        } else {
            Write-Host "❌ MigrationRunner build failed!" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "❌ Error running migrations: $_" -ForegroundColor Red
        return $false
    }
    finally {
        Pop-Location
    }
}

# Function to verify database integrity
function Test-DatabaseIntegrity {
    Write-Host "Verifying database integrity..." -ForegroundColor Cyan
    
    try {
        # Test basic connectivity
        $testQuery = "SELECT COUNT(*) as TableCount FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'"
        $result = sqlcmd -S "$ServerInstance" -d "$DatabaseName" -Q $testQuery -h -1 -W
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Database connectivity verified. Tables found: $result" -ForegroundColor Green
            
            # Test specific tables
            $tables = @("AspNetUsers", "AspNetRoles", "Categories", "Products", "Bookstores", "Customers", "Orders")
            $allTablesExist = $true
            
            foreach ($table in $tables) {
                $tableQuery = "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '$table'"
                $tableExists = sqlcmd -S "$ServerInstance" -d "$DatabaseName" -Q $tableQuery -h -1 -W
                
                if ($tableExists -gt 0) {
                    Write-Host "  ✅ Table $table exists" -ForegroundColor Green
                } else {
                    Write-Host "  ❌ Table $table missing!" -ForegroundColor Red
                    $allTablesExist = $false
                }
            }
            
            return $allTablesExist
        } else {
            Write-Host "❌ Database connectivity test failed!" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "❌ Error verifying database: $_" -ForegroundColor Red
        return $false
    }
}

# Function to validate seeded data
function Validate-SeededData {
    Write-Host "Validating seeded data..." -ForegroundColor Cyan
    
    try {
        # Check if admin user exists
        $adminQuery = "SELECT COUNT(*) FROM AspNetUsers WHERE Email = 'olatunjitoluwanimi90@yahoo.com'"
        $adminExists = sqlcmd -S "$ServerInstance" -d "$DatabaseName" -Q $adminQuery -h -1 -W
        
        if ($adminExists -gt 0) {
            Write-Host "  ✅ Admin user exists" -ForegroundColor Green
        } else {
            Write-Host "  ❌ Admin user missing!" -ForegroundColor Red
        }
        
        # Check if roles exist
        $rolesQuery = "SELECT COUNT(*) FROM AspNetRoles WHERE Name IN ('Admin', 'Bookstore', 'Customer', 'DeliveryDriver')"
        $rolesCount = sqlcmd -S "$ServerInstance" -d "$DatabaseName" -Q $rolesQuery -h -1 -W
        
        if ($rolesCount -ge 4) {
            Write-Host "  ✅ All required roles exist" -ForegroundColor Green
        } else {
            Write-Host "  ❌ Some roles missing! Found: $rolesCount" -ForegroundColor Red
        }
        
        # Check if categories exist
        $categoriesQuery = "SELECT COUNT(*) FROM Categories"
        $categoriesCount = sqlcmd -S "$ServerInstance" -d "$DatabaseName" -Q $categoriesQuery -h -1 -W
        
        if ($categoriesCount -gt 0) {
            Write-Host "  ✅ Categories seeded ($categoriesCount categories)" -ForegroundColor Green
        } else {
            Write-Host "  ❌ No categories found!" -ForegroundColor Red
        }
        
        # Check if sample products exist
        $productsQuery = "SELECT COUNT(*) FROM Products"
        $productsCount = sqlcmd -S "$ServerInstance" -d "$DatabaseName" -Q $productsQuery -h -1 -W
        
        if ($productsCount -gt 0) {
            Write-Host "  ✅ Products seeded ($productsCount products)" -ForegroundColor Green
        } else {
            Write-Host "  ❌ No products found!" -ForegroundColor Red
        }
        
        return ($adminExists -gt 0 -and $rolesCount -ge 4 -and $categoriesCount -gt 0 -and $productsCount -gt 0)
    }
    catch {
        Write-Host "❌ Error validating seeded data: $_" -ForegroundColor Red
        return $false
    }
}

# Function to check migration history
function Get-MigrationHistory {
    Write-Host "Checking migration history..." -ForegroundColor Cyan
    
    try {
        $migrationQuery = "SELECT MigrationId, ProductVersion FROM __MigrationHistory ORDER BY MigrationId DESC"
        $migrations = sqlcmd -S "$ServerInstance" -d "$DatabaseName" -Q $migrationQuery -W -s " | "
        
        Write-Host "Migration History:" -ForegroundColor Yellow
        Write-Host $migrations -ForegroundColor Gray
        
        return $true
    }
    catch {
        Write-Host "❌ Error checking migration history: $_" -ForegroundColor Red
        return $false
    }
}

# Main execution
Write-Host "Starting migration testing process..." -ForegroundColor Green
Write-Host ""

# Step 1: Create backup (if not skipped)
$backupFile = $null
if (-not $SkipBackup) {
    Write-Host "STEP 1: Creating Database Backup" -ForegroundColor Magenta
    $backupFile = Create-DatabaseBackup "PreMigration"
    
    if ($null -eq $backupFile) {
        Write-Host "❌ Backup creation failed. Exiting." -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
}

# Step 2: Test Entity Framework migrations
Write-Host "STEP 2: Testing Entity Framework Migrations" -ForegroundColor Magenta
$migrationSuccess = Test-EntityFrameworkMigrations

if (-not $migrationSuccess) {
    Write-Host "❌ Migration testing failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 3: Verify database integrity
Write-Host "STEP 3: Verifying Database Integrity" -ForegroundColor Magenta
$integritySuccess = Test-DatabaseIntegrity

if (-not $integritySuccess) {
    Write-Host "❌ Database integrity verification failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 4: Validate seeded data
Write-Host "STEP 4: Validating Seeded Data" -ForegroundColor Magenta
$dataValidationSuccess = Validate-SeededData

if (-not $dataValidationSuccess) {
    Write-Host "❌ Data validation failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 5: Check migration history
Write-Host "STEP 5: Checking Migration History" -ForegroundColor Magenta
Get-MigrationHistory

Write-Host ""

# Summary
Write-Host "=== MIGRATION TESTING SUMMARY ===" -ForegroundColor Green
Write-Host "✅ Database backup created: $(if($backupFile){$backupFile}else{'Skipped'})" -ForegroundColor Green
Write-Host "✅ Entity Framework migrations tested successfully" -ForegroundColor Green
Write-Host "✅ Database integrity verified" -ForegroundColor Green
Write-Host "✅ Seeded data validated" -ForegroundColor Green
Write-Host "✅ Migration history checked" -ForegroundColor Green

if ($backupFile) {
    Write-Host ""
    Write-Host "📁 Backup file location: $backupFile" -ForegroundColor Cyan
    Write-Host "💡 To restore this backup, use:" -ForegroundColor Yellow
    Write-Host "sqlcmd -S \"$ServerInstance\" -Q \"RESTORE DATABASE [$DatabaseName] FROM DISK = '$backupFile'\"" -ForegroundColor Gray
}

Write-Host ""
Write-Host "🎉 All migration tests passed successfully!" -ForegroundColor Green
Write-Host "The database is ready for deployment." -ForegroundColor Green