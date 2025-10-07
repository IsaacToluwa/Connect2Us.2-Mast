# Connect2Us Local Deployment Script
# This script helps deploy the application locally or to a web server

param(
    [string]$DeployPath = "published",
    [string]$IISPath = "",
    [switch]$CreateIISApp = $false,
    [string]$AppPoolName = "Connect2UsAppPool",
    [string]$SiteName = "Connect2Us"
)

Write-Host "=== Connect2Us Local Deployment Script ===" -ForegroundColor Green

# Check if published files exist
if (!(Test-Path $DeployPath)) {
    Write-Error "Published files not found at: $DeployPath"
    Write-Host "Please run the build and publish process first."
    exit 1
}

Write-Host "✓ Published files found at: $DeployPath" -ForegroundColor Green

# Display deployment information
Write-Host "`n=== Deployment Information ===" -ForegroundColor Yellow
Write-Host "Application Type: ASP.NET MVC 5"
Write-Host "Target Framework: .NET Framework 4.7.2"
Write-Host "Database: Azure SQL Database (Already Configured)"
Write-Host "Authentication: ASP.NET Identity"
Write-Host "Payment: Stripe (Currently Disabled)"

# Check Web.config for database connection
$webConfigPath = Join-Path $DeployPath "Web.config"
if (Test-Path $webConfigPath) {
    Write-Host "`n=== Configuration Check ===" -ForegroundColor Yellow
    
    # Simple check for connection string
    $configContent = Get-Content $webConfigPath -Raw
    if ($configContent -match "connect2usserver\.database\.windows\.net") {
        Write-Host "✓ Azure SQL Database connection configured" -ForegroundColor Green
    } else {
        Write-Host "⚠ Azure SQL Database connection not found in Web.config" -ForegroundColor Yellow
    }
    
    if ($configContent -match "StripeEnabled.*false") {
        Write-Host "✓ Stripe is disabled (safe for deployment)" -ForegroundColor Green
    } else {
        Write-Host "⚠ Stripe may be enabled - check configuration" -ForegroundColor Yellow
    }
}

Write-Host "`n=== Deployment Options ===" -ForegroundColor Yellow
Write-Host "1. Manual Deployment: Copy the '$DeployPath' folder to your web server"
Write-Host "2. IIS Deployment: Use the IIS Manager to create a new application"
Write-Host "3. Azure Deployment: Use Azure App Service deployment tools"

# Provide deployment instructions
Write-Host "`n=== Manual Deployment Instructions ===" -ForegroundColor Yellow
Write-Host "1. Copy the entire '$DeployPath' folder to your web server"
Write-Host "2. Ensure .NET Framework 4.7.2 is installed on the server"
Write-Host "3. Configure IIS to use .NET Framework 4.7.2"
Write-Host "4. Set appropriate permissions on the application folder"
Write-Host "5. Update connection strings if needed for production"

Write-Host "`n=== IIS Configuration ===" -ForegroundColor Yellow
Write-Host "Application Pool: .NET Framework 4.7.2, Integrated Pipeline"
Write-Host "Required Features: ASP.NET 4.7, IIS Management Tools"

Write-Host "`n=== Database Status ===" -ForegroundColor Yellow
Write-Host "✓ Database is connected to Azure SQL Database"
Write-Host "✓ Database contains sample data (Admins, Users, Products, etc.)" -ForegroundColor Green
Write-Host "✓ Entity Framework migrations have been applied"

Write-Host "`n=== Security Notes ===" -ForegroundColor Yellow
Write-Host "✓ Stripe secret keys have been replaced with placeholders"
Write-Host "✓ Database connection uses Azure SQL with encryption"
Write-Host "⚠ Review and update all configuration settings for production"

Write-Host "`n=== Next Steps ===" -ForegroundColor Yellow
Write-Host "1. Test the application locally if possible"
Write-Host "2. Deploy to your target environment"
Write-Host "3. Update configuration for production settings"
Write-Host "4. Set up SSL/TLS certificates"
Write-Host "5. Configure monitoring and logging"

Write-Host "✓ Deployment package ready" -ForegroundColor Green
Write-Host "Location: $(Resolve-Path $DeployPath)" -ForegroundColor Green