# Quick Azure Configuration Check
# This script helps verify your Azure setup

Write-Host "Azure Configuration Check" -ForegroundColor Green
Write-Host "========================" -ForegroundColor Green

Write-Host "`n1. Checking Azure CLI installation..." -ForegroundColor Yellow
$azVersion = az --version 2>$null
if ($azVersion) {
    Write-Host "✓ Azure CLI is installed" -ForegroundColor Green
} else {
    Write-Host "✗ Azure CLI is not installed. Please install it first." -ForegroundColor Red
    Write-Host "Download from: https://aka.ms/installazurecliwindows" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n2. Checking Azure login status..." -ForegroundColor Yellow
$azAccount = az account show 2>$null
if ($azAccount) {
    Write-Host "✓ You are logged into Azure" -ForegroundColor Green
    $subscription = az account show --query "name" -o tsv
    Write-Host "Current subscription: $subscription" -ForegroundColor Green
} else {
    Write-Host "✗ You are not logged into Azure" -ForegroundColor Red
    Write-Host "Please run: az login" -ForegroundColor Yellow
}

Write-Host "`n3. Checking for existing Connect2Us app registration..." -ForegroundColor Yellow
$app = az ad app list --display-name "Connect2Us-GitHub-Actions" --query "[0]" -o json 2>$null
if ($app -and $app -ne "null") {
    Write-Host "✓ Found existing Connect2Us-GitHub-Actions app" -ForegroundColor Green
    $appId = az ad app list --display-name "Connect2Us-GitHub-Actions" --query "[0].appId" -o tsv
    Write-Host "App ID: $appId" -ForegroundColor Green
} else {
    Write-Host "✗ No Connect2Us-GitHub-Actions app found" -ForegroundColor Yellow
    Write-Host "This is expected if you haven't set it up yet" -ForegroundColor Yellow
}

Write-Host "`n4. Required information for GitHub secrets:" -ForegroundColor Cyan
if ($azAccount) {
    $tenantId = az account show --query "tenantId" -o tsv
    $subscriptionId = az account show --query "id" -o tsv
    
    Write-Host "Tenant ID: $tenantId" -ForegroundColor White
    Write-Host "Subscription ID: $subscriptionId" -ForegroundColor White
    
    if ($app -and $app -ne "null") {
        Write-Host "Client ID: $appId" -ForegroundColor White
    } else {
        Write-Host "Client ID: (will be provided after app registration)" -ForegroundColor Gray
    }
}

Write-Host "`nNext steps:" -ForegroundColor Green
Write-Host "1. Run the setup-oidc-authentication.ps1 script for detailed setup instructions"
Write-Host "2. Create the Azure app registration if it doesn't exist"
Write-Host "3. Add the GitHub secrets with the values shown above"
Write-Host "4. Trigger a new workflow run to test the authentication"