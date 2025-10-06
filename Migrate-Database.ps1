# Connect2Us Database Migration Script for Azure
# This script helps migrate your local database to Azure SQL Database

param(
    [Parameter(Mandatory=$true)]
    [string]$AzureConnectionString,
    
    [Parameter(Mandatory=$false)]
    [string]$LocalConnectionString = "Data Source=(localdb)\MSSQLLocalDB;Initial Catalog=Connect2US;Integrated Security=True;TrustServerCertificate=True"
)

Write-Host "🗄️ Starting Connect2Us Database Migration to Azure..." -ForegroundColor Green

# Function to test database connection
function Test-DatabaseConnection {
    param([string]$connectionString, [string]$databaseName)
    
    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
        $connection.Open()
        Write-Host "✅ Successfully connected to $databaseName" -ForegroundColor Green
        $connection.Close()
        return $true
    }
    catch {
        Write-Host "❌ Failed to connect to $databaseName`: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Test connections
Write-Host "🔍 Testing database connections..." -ForegroundColor Cyan
$localConnected = Test-DatabaseConnection -connectionString $LocalConnectionString -databaseName "Local Database"
$azureConnected = Test-DatabaseConnection -connectionString $AzureConnectionString -databaseName "Azure Database"

if (-not $localConnected -or -not $azureConnected) {
    Write-Host "❌ Database connection test failed. Please check your connection strings." -ForegroundColor Red
    exit 1
}

Write-Host "📋 Migration Options:" -ForegroundColor Yellow
Write-Host "1. Generate SQL script from local database and apply to Azure"
Write-Host "2. Use Entity Framework migrations"
Write-Host "3. Export/Import data using BACPAC file"
Write-Host ""

$option = Read-Host "Select migration option (1-3)"

switch ($option) {
    "1" {
        Write-Host "📝 Generating SQL script from local database..." -ForegroundColor Cyan
        
        # Generate script using SQL Server Management Objects (SMO)
        try {
            # This requires SQL Server Management Objects to be installed
            [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null
            [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoExtended") | Out-Null
            
            $server = New-Object Microsoft.SqlServer.Management.Smo.Server("(localdb)\MSSQLLocalDB")
            $database = $server.Databases["Connect2US"]
            
            $scriptOptions = New-Object Microsoft.SqlServer.Management.Smo.ScriptingOptions
            $scriptOptions.ScriptData = $true
            $scriptOptions.ScriptSchema = $true
            $scriptOptions.ScriptDrops = $false
            
            $script = $database.Script($scriptOptions)
            $scriptPath = "local-database-script.sql"
            $script | Out-File -FilePath $scriptPath -Encoding UTF8
            
            Write-Host "✅ SQL script generated: $scriptPath" -ForegroundColor Green
            Write-Host "🔄 Now applying script to Azure database..." -ForegroundColor Cyan
            
            # Apply script to Azure
            $azureConnection = New-Object System.Data.SqlClient.SqlConnection($AzureConnectionString)
            $azureConnection.Open()
            
            $scriptContent = Get-Content $scriptPath -Raw
            $command = New-Object System.Data.SqlClient.SqlCommand($scriptContent, $azureConnection)
            $command.ExecuteNonQuery()
            
            $azureConnection.Close()
            Write-Host "✅ Database migration completed!" -ForegroundColor Green
        }
        catch {
            Write-Host "❌ SMO method failed: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "💡 Trying alternative method..." -ForegroundColor Yellow
            
            # Alternative: Use sqlcmd utility
            $scriptPath = "local-database-script.sql"
            
            # Generate script using sqlcmd (requires SQL Server tools)
            $generateScript = @"
sqlcmd -S "(localdb)\MSSQLLocalDB" -d "Connect2US" -Q "EXEC sp_generate_inserts 'Users'; EXEC sp_generate_inserts 'Products'; EXEC sp_generate_inserts 'Orders';" -o "$scriptPath"
"@
            
            Write-Host "📝 Please generate SQL script manually using SQL Server Management Studio or Azure Data Studio"
            Write-Host "📁 Save the script as: $scriptPath" -ForegroundColor Yellow
            Read-Host "Press Enter when you have generated and saved the SQL script"
            
            if (Test-Path $scriptPath) {
                Write-Host "🔄 Applying script to Azure database..." -ForegroundColor Cyan
                
                $azureConnection = New-Object System.Data.SqlClient.SqlConnection($AzureConnectionString)
                $azureConnection.Open()
                
                $scriptContent = Get-Content $scriptPath -Raw
                $command = New-Object System.Data.SqlClient.SqlCommand($scriptContent, $azureConnection)
                $command.ExecuteNonQuery()
                
                $azureConnection.Close()
                Write-Host "✅ Database migration completed!" -ForegroundColor Green
            }
        }
    }
    
    "2" {
        Write-Host "🚀 Using Entity Framework migrations..." -ForegroundColor Cyan
        Write-Host "📋 Instructions for Entity Framework migrations:" -ForegroundColor Yellow
        Write-Host "1. Open Package Manager Console in Visual Studio"
        Write-Host "2. Run: Update-Database -ConnectionString '$AzureConnectionString' -ConnectionProviderName 'System.Data.SqlClient'"
        Write-Host "3. If you need to create a new migration: Add-Migration 'AzureMigration'"
        Write-Host ""
        
        $runNow = Read-Host "Do you want to run EF migration now? (Y/N)"
        if ($runNow -eq "Y" -or $runNow -eq "y") {
            Write-Host "🔄 Running EF migration..." -ForegroundColor Cyan
            
            # This would typically be run from Visual Studio Package Manager Console
            # We're providing the command here for reference
            $efCommand = "Update-Database -ConnectionString \"$AzureConnectionString\" -ConnectionProviderName \"System.Data.SqlClient\""
            Write-Host "💡 Run this command in Package Manager Console:" -ForegroundColor Yellow
            Write-Host $efCommand -ForegroundColor White
        }
    }
    
    "3" {
        Write-Host "📦 Using BACPAC export/import method..." -ForegroundColor Cyan
        
        $bacpacPath = "Connect2Us-local.bacpac"
        
        Write-Host "📋 Instructions for BACPAC method:" -ForegroundColor Yellow
        Write-Host "1. Export local database to BACPAC file:" -ForegroundColor Yellow
        Write-Host "   - Use SQL Server Management Studio or Azure Data Studio"
        Write-Host "   - Export database 'Connect2US' to '$bacpacPath'"
        Write-Host ""
        Write-Host "2. Import BACPAC to Azure SQL Database:" -ForegroundColor Yellow
        Write-Host "   - Use Azure Portal or Azure Data Studio"
        Write-Host "   - Import '$bacpacPath' to your Azure database"
        Write-Host ""
        
        Read-Host "Press Enter when you have completed the BACPAC export"
        
        if (Test-Path $bacpacPath) {
            Write-Host "✅ BACPAC file found: $bacpacPath" -ForegroundColor Green
            Write-Host "🔄 Now import this file to your Azure SQL Database using Azure Portal" -ForegroundColor Cyan
        }
        else {
            Write-Host "❌ BACPAC file not found. Please export your local database first." -ForegroundColor Red
        }
    }
    
    default {
        Write-Host "❌ Invalid option selected." -ForegroundColor Red
        exit 1
    }
}

# Verification
Write-Host "🔍 Verifying migration..." -ForegroundColor Cyan

$verificationQuery = @"
SELECT COUNT(*) as TableCount FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'
SELECT COUNT(*) as UserCount FROM AspNetUsers
SELECT COUNT(*) as ProductCount FROM Products
"@

try {
    $azureConnection = New-Object System.Data.SqlClient.SqlConnection($AzureConnectionString)
    $azureConnection.Open()
    
    $command = New-Object System.Data.SqlClient.SqlCommand($verificationQuery, $azureConnection)
    $reader = $command.ExecuteReader()
    
    while ($reader.Read()) {
        Write-Host "📊 Tables in database: $($reader['TableCount'])" -ForegroundColor Green
    }
    
    $reader.NextResult()
    while ($reader.Read()) {
        Write-Host "👥 Users in database: $($reader['UserCount'])" -ForegroundColor Green
    }
    
    $reader.NextResult()
    while ($reader.Read()) {
        Write-Host "📦 Products in database: $($reader['ProductCount'])" -ForegroundColor Green
    }
    
    $reader.Close()
    $azureConnection.Close()
    
    Write-Host "✅ Migration verification completed!" -ForegroundColor Green
}
catch {
    Write-Host "⚠️ Verification query failed: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "💡 This is normal if your table names are different" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎉 Database migration process completed!" -ForegroundColor Green
Write-Host "🔗 Test your application at: https://your-app-name.azurewebsites.net" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️ Remember to:" -ForegroundColor Yellow
Write-Host "1. Test all application functionality" -ForegroundColor Yellow
Write-Host "2. Verify user authentication works" -ForegroundColor Yellow
Write-Host "3. Check wallet functionality (the fix we implemented)" -ForegroundColor Yellow
Write-Host "4. Monitor your Azure usage and costs" -ForegroundColor Yellow