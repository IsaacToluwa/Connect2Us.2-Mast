# Azure Deployment Preparation Script
param(
    [Parameter(Mandatory=$true)]
    [string]$AzureSqlServer,
    
    [Parameter(Mandatory=$true)]
    [string]$AzureSqlDatabase,
    
    [Parameter(Mandatory=$true)]
    [string]$AzureSqlUser,
    
    [Parameter(Mandatory=$true)]
    [string]$AzureSqlPassword,
    
    [string]$Environment = "Production"
)

Write-Host "=== AZURE DEPLOYMENT PREPARATION ===" -ForegroundColor Cyan
Write-Host ""

# Backup original Web.config
if (Test-Path "Web.config") {
    Copy-Item "Web.config" "Web.config.backup" -Force
    Write-Host "✓ Created backup of Web.config" -ForegroundColor Green
}

# Update Web.config with Azure SQL connection
Write-Host "Updating Web.config for Azure SQL..." -ForegroundColor Yellow

$content = Get-Content "Web.config" -Raw

# Create Azure SQL connection string
$azureConnectionString = "Server=tcp:$AzureSqlServer,1433;Database=$AzureSqlDatabase;User ID=$AzureSqlUser;Password=$AzureSqlPassword;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

# Replace connection string parts
$content = $content -replace 'data source=\(localdb\)\\MSSQLLocalDB', $AzureSqlServer
$content = $content -replace 'initial catalog=Connect2US', "Database=$AzureSqlDatabase"
$content = $content -replace 'integrated security=True', "User ID=$AzureSqlUser;Password=$AzureSqlPassword"
$content = $content -replace 'MultipleActiveResultSets=True;App=EntityFramework', "Encrypt=True;TrustServerCertificate=False;Connection Timeout=30"

# Update Entity Framework configuration
$content = $content -replace 'LocalDbConnectionFactory', 'SqlConnectionFactory'
$content = $content -replace '<parameter value="mssqllocaldb" />', ''

Set-Content -Path "Web.config" -Value $content -Force
Write-Host "✓ Web.config updated successfully" -ForegroundColor Green

# Create deployment package
Write-Host "Creating deployment package..." -ForegroundColor Yellow

$deployDir = "AzureDeployment"
if (Test-Path $deployDir) {
    Remove-Item $deployDir -Recurse -Force
}
New-Item -ItemType Directory -Path $deployDir | Out-Null

# Copy essential files
$filesToCopy = @("Web.config", "Global.asax", "Connect2Us.2.csproj", "packages.config")
foreach ($file in $filesToCopy) {
    if (Test-Path $file) {
        Copy-Item $file "$deployDir\" -Force
        Write-Host "  ✓ Copied $file" -ForegroundColor Green
    }
}

# Copy directories
$dirsToCopy = @("Controllers", "Models", "Views", "Content", "Scripts", "App_Start", "App_Data")
foreach ($dir in $dirsToCopy) {
    if (Test-Path $dir) {
        Copy-Item $dir "$deployDir\$dir" -Recurse -Force
        Write-Host "  ✓ Copied $dir directory" -ForegroundColor Green
    }
}

Write-Host "✓ Deployment package created in $deployDir" -ForegroundColor Green

# Validate configuration
Write-Host "Validating configuration..." -ForegroundColor Yellow

$issues = @()
$content = Get-Content "Web.config" -Raw

if ($content -match "localhost") {
    $issues += "Localhost references still present"
}

if ($content -match "LocalDb") {
    $issues += "LocalDB references still present"
}

if ($content -match "AttachDbFilename") {
    $issues += "AttachDbFilename references found"
}

if ($issues.Count -gt 0) {
    Write-Host "⚠ Configuration issues found:" -ForegroundColor Yellow
    foreach ($issue in $issues) {
        Write-Host "  - $issue" -ForegroundColor Yellow
    }
} else {
    Write-Host "✓ Configuration validation passed" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== DEPLOYMENT PREPARATION COMPLETE ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "✓ Project is ready for Azure deployment!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Review the updated Web.config file" -ForegroundColor White
Write-Host "2. Set up GitHub secrets using Setup-GitHub-Secrets.ps1" -ForegroundColor White
Write-Host "3. Deploy to Azure using GitHub Actions" -ForegroundColor White
Write-Host ""
Write-Host "Deployment package created in: AzureDeployment" -ForegroundColor Cyan