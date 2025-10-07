# Simple Azure Resource Creation Script
# This script creates Azure resources without complex authentication

param(
    [string]$ResourceGroupName = "connect2us-rg",
    [string]$Location = "eastus",
    [string]$AppServiceName = "connect2us-app",
    [string]$SqlServerName = "connect2usserver",
    [string]$SqlDatabaseName = "Connect2US",
    [string]$SqlAdminUser = "connect_admin",
    [string]$SqlAdminPassword = "Test@123"
)

Write-Host "=== Creating Azure Resources ===" -ForegroundColor Green
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor White
Write-Host "App Service: $AppServiceName" -ForegroundColor White
Write-Host "SQL Server: $SqlServerName" -ForegroundColor White
Write-Host "Location: $Location" -ForegroundColor White

# Create Resource Group
try {
    Write-Host "Creating resource group..." -ForegroundColor Yellow
    New-AzResourceGroup -Name $ResourceGroupName -Location $Location -ErrorAction Stop
    Write-Host "✓ Resource group created successfully" -ForegroundColor Green
} catch {
    Write-Host "Resource group creation failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Create App Service Plan
try {
    Write-Host "Creating app service plan..." -ForegroundColor Yellow
    New-AzAppServicePlan -Name "$($AppServiceName)-plan" -Location $Location -ResourceGroupName $ResourceGroupName -Tier "Free" -ErrorAction Stop
    Write-Host "✓ App service plan created successfully" -ForegroundColor Green
} catch {
    Write-Host "App service plan creation failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Create Web App
try {
    Write-Host "Creating web app..." -ForegroundColor Yellow
    New-AzWebApp -Name $AppServiceName -Location $Location -AppServicePlan "$($AppServiceName)-plan" -ResourceGroupName $ResourceGroupName -ErrorAction Stop
    Write-Host "✓ Web app created successfully" -ForegroundColor Green
    Write-Host "Web App URL: https://$AppServiceName.azurewebsites.net" -ForegroundColor Cyan
} catch {
    Write-Host "Web app creation failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Create SQL Server
try {
    Write-Host "Creating SQL server..." -ForegroundColor Yellow
    New-AzSqlServer -ServerName $SqlServerName -Location $Location -ResourceGroupName $ResourceGroupName -SqlAdministratorCredentials (New-Object System.Management.Automation.PSCredential($SqlAdminUser, (ConvertTo-SecureString $SqlAdminPassword -AsPlainText -Force))) -ErrorAction Stop
    Write-Host "✓ SQL server created successfully" -ForegroundColor Green
} catch {
    Write-Host "SQL server creation failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Create SQL Database
try {
    Write-Host "Creating SQL database..." -ForegroundColor Yellow
    New-AzSqlDatabase -DatabaseName $SqlDatabaseName -ServerName $SqlServerName -ResourceGroupName $ResourceGroupName -Edition "Basic" -ErrorAction Stop
    Write-Host "✓ SQL database created successfully" -ForegroundColor Green
} catch {
    Write-Host "SQL database creation failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Create firewall rule for SQL Server
try {
    Write-Host "Creating SQL firewall rule..." -ForegroundColor Yellow
    New-AzSqlServerFirewallRule -FirewallRuleName "AllowAzureServices" -StartIpAddress "0.0.0.0" -EndIpAddress "0.0.0.0" -ServerName $SqlServerName -ResourceGroupName $ResourceGroupName -ErrorAction Stop
    Write-Host "✓ SQL firewall rule created successfully" -ForegroundColor Green
} catch {
    Write-Host "SQL firewall rule creation failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "=== Resource Creation Complete ===" -ForegroundColor Green