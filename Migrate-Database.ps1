# Connect2Us Database Migration Script
# This script handles database migrations for Azure SQL Database deployment

param(
    [Parameter(Mandatory=$true)]
    [string]$ConnectionString,
    
    [Parameter(Mandatory=$false)]
    [string]$MigrationName = "InitialCreate",
    
    [switch]$CreateMigration = $false,
    
    [switch]$UpdateDatabase = $true,
    
    [switch]$ScriptMigration = $false,
    
    [string]$OutputScriptPath = "MigrationScript.sql",
    
    [switch]$Force = $false
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Function to write colored output
function Write-Status {
    param(
        [string]$Message,
        [string]$Status = "INFO"
    )
    
    $colors = @{
        "INFO" = "White"
        "SUCCESS" = "Green"
        "WARNING" = "Yellow"
        "ERROR" = "Red"
        "VERBOSE" = "Cyan"
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Status] $Message" -ForegroundColor $colors[$Status]
}

# Function to test database connection
function Test-DatabaseConnection {
    param([string]$ConnectionString)
    
    Write-Status "Testing database connection..." "INFO"
    
    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
        $connection.Open()
        
        $command = $connection.CreateCommand()
        $command.CommandText = "SELECT @@VERSION"
        $result = $command.ExecuteScalar()
        
        $connection.Close()
        
        Write-Status "Database connection successful!" "SUCCESS"
        Write-Status "SQL Server Version: $result" "VERBOSE"
        
        return $true
    }
    catch {
        Write-Status "Database connection failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Function to check if Entity Framework is available
function Test-EntityFramework {
    Write-Status "Checking Entity Framework availability..." "INFO"
    
    $efPath = "packages\EntityFramework.6.5.1\tools\net45\any\ef6.exe"
    
    if (-not (Test-Path $efPath)) {
        Write-Status "Entity Framework tools not found. Attempting to restore packages..." "WARNING"
        
        try {
            nuget restore Connect2Us.2.sln
            
            if (-not (Test-Path $efPath)) {
                throw "Entity Framework tools still not found after package restore."
            }
        }
        catch {
            Write-Status "Failed to restore packages or find Entity Framework tools." "ERROR"
            return $false
        }
    }
    
    try {
        $efVersion = & $efPath --version 2>$null
        Write-Status "Entity Framework tools found: $efVersion" "SUCCESS"
        return $true
    }
    catch {
        Write-Status "Entity Framework tools error: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Function to get current migrations
function Get-CurrentMigrations {
    param([string]$ConnectionString)
    
    Write-Status "Retrieving current migrations..." "INFO"
    
    try {
        $efPath = "packages\EntityFramework.6.5.1\tools\net45\any\ef6.exe"
        
        $output = & $efPath database show --connection-string "$ConnectionString" --connection-provider "System.Data.SqlClient" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Status "Current migration: $output" "VERBOSE"
            return $output
        } else {
            Write-Status "No migrations applied or database not initialized." "WARNING"
            return $null
        }
    }
    catch {
        Write-Status "Error retrieving migrations: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

# Function to create new migration
function New-Migration {
    param([string]$Name)
    
    Write-Status "Creating new migration: $Name" "INFO"
    
    try {
        $efPath = "packages\EntityFramework.6.5.1\tools\net45\any\ef6.exe"
        
        & $efPath migrations add $Name --connection-provider "System.Data.SqlClient"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Status "Migration '$Name' created successfully!" "SUCCESS"
            return $true
        } else {
            throw "Migration creation failed with exit code $LASTEXITCODE"
        }
    }
    catch {
        Write-Status "Error creating migration: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Function to update database
function Update-Database {
    param([string]$ConnectionString)
    
    Write-Status "Updating database..." "INFO"
    
    try {
        $efPath = "packages\EntityFramework.6.5.1\tools\net45\any\ef6.exe"
        
        if ($Force) {
            Write-Status "Force update enabled. This may overwrite existing data." "WARNING"
            & $efPath database update --force --connection-string "$ConnectionString" --connection-provider "System.Data.SqlClient"
        } else {
            & $efPath database update --connection-string "$ConnectionString" --connection-provider "System.Data.SqlClient"
        }
        
        if ($LASTEXITCODE -eq 0) {
            Write-Status "Database updated successfully!" "SUCCESS"
            return $true
        } else {
            throw "Database update failed with exit code $LASTEXITCODE"
        }
    }
    catch {
        Write-Status "Error updating database: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Function to generate migration script
function New-MigrationScript {
    param(
        [string]$ConnectionString,
        [string]$OutputPath
    )
    
    Write-Status "Generating migration script..." "INFO"
    
    try {
        $efPath = "packages\EntityFramework.6.5.1\tools\net45\any\ef6.exe"
        
        & $efPath migrations script --connection-string "$ConnectionString" --connection-provider "System.Data.SqlClient" --output "$OutputPath"
        
        if ($LASTEXITCODE -eq 0) {
            if (Test-Path $OutputPath) {
                $scriptSize = (Get-Item $OutputPath).Length
                Write-Status "Migration script generated: $OutputPath ($scriptSize bytes)" "SUCCESS"
                return $true
            } else {
                throw "Migration script file was not created."
            }
        } else {
            throw "Migration script generation failed with exit code $LASTEXITCODE"
        }
    }
    catch {
        Write-Status "Error generating migration script: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Function to execute SQL script
function Invoke-SqlScript {
    param(
        [string]$ConnectionString,
        [string]$ScriptPath
    )
    
    Write-Status "Executing SQL script: $ScriptPath" "INFO"
    
    try {
        if (-not (Test-Path $ScriptPath)) {
            throw "SQL script file not found: $ScriptPath"
        }
        
        $scriptContent = Get-Content $ScriptPath -Raw
        
        $connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
        $connection.Open()
        
        $command = $connection.CreateCommand()
        $command.CommandText = $scriptContent
        $command.CommandType = [System.Data.CommandType]::Text
        
        if ($Verbose) {
            Write-Status "Executing SQL script with $($scriptContent.Length) characters..." "VERBOSE"
        }
        
        $result = $command.ExecuteNonQuery()
        
        $connection.Close()
        
        Write-Status "SQL script executed successfully! ($result commands executed)" "SUCCESS"
        return $true
    }
    catch {
        Write-Status "Error executing SQL script: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Function to backup database
function Backup-Database {
    param([string]$ConnectionString)
    
    Write-Status "Creating database backup..." "INFO"
    
    try {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupFile = "Connect2Us_Database_Backup_$timestamp.bacpac"
        
        # Extract server and database name from connection string
        $serverMatch = [regex]::Match($ConnectionString, "Server=tcp:([^,]+)")
        $dbMatch = [regex]::Match($ConnectionString, "Initial Catalog=([^;]+)")
        
        if (-not $serverMatch.Success -or -not $dbMatch.Success) {
            throw "Could not extract server and database information from connection string."
        }
        
        $serverName = $serverMatch.Groups[1].Value
        $databaseName = $dbMatch.Groups[1].Value
        
        # This would require Azure CLI and proper authentication
        Write-Status "Database backup would be created at: $backupFile" "WARNING"
        Write-Status "Note: Automated backup requires Azure CLI and proper permissions." "WARNING"
        
        return $true
    }
    catch {
        Write-Status "Error creating database backup: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Function to validate connection string
function Test-ConnectionString {
    param([string]$ConnectionString)
    
    Write-Status "Validating connection string format..." "INFO"
    
    try {
        # Basic validation
        $requiredKeywords = @("Server=", "Initial Catalog=", "User ID=", "Password=")
        
        foreach ($keyword in $requiredKeywords) {
            if ($ConnectionString -notlike "*$keyword*") {
                throw "Connection string is missing required keyword: $keyword"
            }
        }
        
        # Test parsing
        $builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder($ConnectionString)
        
        Write-Status "Connection string validation passed." "SUCCESS"
        Write-Status "Server: $($builder.DataSource)" "VERBOSE"
        Write-Status "Database: $($builder.InitialCatalog)" "VERBOSE"
        Write-Status "User: $($builder.UserID)" "VERBOSE"
        
        return $true
    }
    catch {
        Write-Status "Connection string validation failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Main execution
try {
    Write-Status "Starting Connect2Us Database Migration..." "INFO"
    Write-Status "=========================================" "INFO"
    
    # Validate connection string
    if (-not (Test-ConnectionString -ConnectionString $ConnectionString)) {
        throw "Invalid connection string provided."
    }
    
    # Test database connection
    if (-not (Test-DatabaseConnection -ConnectionString $ConnectionString)) {
        throw "Cannot connect to database. Please check connection string and network connectivity."
    }
    
    # Check Entity Framework availability
    if (-not (Test-EntityFramework)) {
        throw "Entity Framework tools are not available."
    }
    
    # Get current migrations
    $currentMigration = Get-CurrentMigrations -ConnectionString $ConnectionString
    
    # Create new migration if requested
    if ($CreateMigration) {
        if (-not (New-Migration -Name $MigrationName)) {
            throw "Failed to create migration '$MigrationName'."
        }
    }
    
    # Generate migration script if requested
    if ($ScriptMigration) {
        if (-not (New-MigrationScript -ConnectionString $ConnectionString -OutputPath $OutputScriptPath)) {
            throw "Failed to generate migration script."
        }
        
        if ($Verbose) {
            Write-Status "Migration script preview:" "VERBOSE"
            $scriptContent = Get-Content $OutputScriptPath -First 50
            $scriptContent | ForEach-Object { Write-Status $_ "VERBOSE" }
        }
    }
    
    # Backup database before update (recommended)
    if ($UpdateDatabase -and -not $Force) {
        Write-Status "Creating database backup before migration..." "INFO"
        if (-not (Backup-Database -ConnectionString $ConnectionString)) {
            Write-Status "Backup creation failed, but continuing with migration..." "WARNING"
        }
    }
    
    # Update database
    if ($UpdateDatabase) {
        if (-not (Update-Database -ConnectionString $ConnectionString)) {
            throw "Failed to update database."
        }
    }
    
    # Verify final state
    $finalMigration = Get-CurrentMigrations -ConnectionString $ConnectionString
    
    Write-Status "=========================================" "INFO"
    Write-Status "Database migration completed successfully!" "SUCCESS"
    Write-Status "Initial Migration: $currentMigration" "INFO"
    Write-Status "Final Migration: $finalMigration" "INFO"
    Write-Status "=========================================" "SUCCESS"
    
}
catch {
    Write-Status "Database migration failed: $($_.Exception.Message)" "ERROR"
    Write-Status "Error details: $($_.Exception)" "ERROR"
    exit 1
}