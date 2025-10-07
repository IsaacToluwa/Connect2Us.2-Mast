# Azure OIDC Authentication Troubleshooting Script
# This script helps diagnose and fix the federated identity authentication issue

Write-Host "Azure OIDC Authentication Troubleshooter" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

Write-Host "`n🔍 DIAGNOSING AUTHENTICATION ISSUE..." -ForegroundColor Yellow

# Check if Azure CLI is available
Write-Host "`n1. Checking Azure CLI availability..." -ForegroundColor Cyan
$azVersion = az --version 2>$null
if ($azVersion) {
    Write-Host "✓ Azure CLI is installed" -ForegroundColor Green
} else {
    Write-Host "✗ Azure CLI is not installed" -ForegroundColor Red
    Write-Host "  Please install Azure CLI: https://aka.ms/installazurecliwindows" -ForegroundColor Yellow
    exit 1
}

# Check current Azure login status
Write-Host "`n2. Checking Azure login status..." -ForegroundColor Cyan
$azAccount = az account show 2>$null
if ($azAccount) {
    Write-Host "✓ You are logged into Azure" -ForegroundColor Green
    $tenantId = az account show --query "tenantId" -o tsv
    $subscriptionId = az account show --query "id" -o tsv
    $subscriptionName = az account show --query "name" -o tsv
    Write-Host "  Tenant ID: $tenantId" -ForegroundColor White
    Write-Host "  Subscription: $subscriptionName ($subscriptionId)" -ForegroundColor White
} else {
    Write-Host "✗ You are not logged into Azure" -ForegroundColor Red
    Write-Host "  Please run: az login" -ForegroundColor Yellow
    exit 1
}

# Check for existing app registration
Write-Host "`n3. Checking for existing Connect2Us app registration..." -ForegroundColor Cyan
$app = az ad app list --display-name "Connect2Us-GitHub-Actions" --query "[0]" -o json 2>$null
if ($app -and $app -ne "null") {
    Write-Host "✓ Found Connect2Us-GitHub-Actions app" -ForegroundColor Green
    $appId = az ad app list --display-name "Connect2Us-GitHub-Actions" --query "[0].appId" -o tsv
    $appObjectId = az ad app list --display-name "Connect2Us-GitHub-Actions" --query "[0].id" -o tsv
    Write-Host "  App ID: $appId" -ForegroundColor White
    Write-Host "  Object ID: $appObjectId" -ForegroundColor White
    
    # Check federated credentials
    Write-Host "`n4. Checking federated credentials..." -ForegroundColor Cyan
    $ficCreds = az ad app federated-credential list --id $appObjectId --query "[?name=='Connect2Us-GitHub-FIC']" -o json 2>$null
    if ($ficCreds -and $ficCreds -ne "[]") {
        Write-Host "✓ Found federated credential 'Connect2Us-GitHub-FIC'" -ForegroundColor Green
        $subject = az ad app federated-credential list --id $appObjectId --query "[?name=='Connect2Us-GitHub-FIC'].subject" -o tsv
        Write-Host "  Subject: $subject" -ForegroundColor White
        
        # Verify the subject matches what GitHub expects
        $expectedSubject = "repo:IsaacToluwa/Connect2Us.2-Mast:environment:Production"
        if ($subject -eq $expectedSubject) {
            Write-Host "✓ Subject matches expected format" -ForegroundColor Green
        } else {
            Write-Host "✗ Subject mismatch!" -ForegroundColor Red
            Write-Host "  Expected: $expectedSubject" -ForegroundColor Yellow
            Write-Host "  Actual: $subject" -ForegroundColor Yellow
            Write-Host "  You need to update the federated credential subject" -ForegroundColor Red
        }
    } else {
        Write-Host "✗ No federated credential 'Connect2Us-GitHub-FIC' found" -ForegroundColor Red
        Write-Host "  You need to create a federated credential" -ForegroundColor Yellow
    }
} else {
    Write-Host "✗ No Connect2Us-GitHub-Actions app found" -ForegroundColor Red
    Write-Host "  You need to create the app registration first" -ForegroundColor Yellow
}

# Check web app permissions
Write-Host "`n5. Checking web app permissions..." -ForegroundColor Cyan
$webApp = az webapp list --query "[?name=='Connect2US']" -o json 2>$null
if ($webApp -and $webApp -ne "[]") {
    Write-Host "✓ Found Connect2US web app" -ForegroundColor Green
    $webAppId = az webapp list --query "[?name=='Connect2US'].id" -o tsv
    Write-Host "  Web App ID: $webAppId" -ForegroundColor White
    
    if ($app -and $app -ne "null") {
        Write-Host "`n6. Checking role assignments..." -ForegroundColor Cyan
        $roleAssignments = az role assignment list --scope $webAppId --query "[?principalName=='Connect2Us-GitHub-Actions']" -o json 2>$null
        if ($roleAssignments -and $roleAssignments -ne "[]") {
            Write-Host "✓ Found role assignments for the app" -ForegroundColor Green
            $roles = az role assignment list --scope $webAppId --query "[?principalName=='Connect2Us-GitHub-Actions'].roleDefinitionName" -o tsv
            Write-Host "  Assigned roles: $($roles -join ', ')" -ForegroundColor White
        } else {
            Write-Host "✗ No role assignments found for the app" -ForegroundColor Red
            Write-Host "  You need to assign 'Website Contributor' role to the app" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "✗ Connect2US web app not found" -ForegroundColor Red
    Write-Host "  Please verify the web app name in Azure" -ForegroundColor Yellow
}

# Summary and next steps
Write-Host "`n📋 SUMMARY:" -ForegroundColor Green
Write-Host "=============" -ForegroundColor Green

if ($azAccount -and $app -and $app -ne "null" -and $ficCreds -and $ficCreds -ne "[]" -and $roleAssignments -and $roleAssignments -ne "[]") {
    Write-Host "✓ All components are configured correctly!" -ForegroundColor Green
    Write-Host "  The authentication should work now." -ForegroundColor Green
} else {
    Write-Host "✗ Missing components detected" -ForegroundColor Red
    Write-Host "  Please follow the setup instructions in setup-oidc-authentication.ps1" -ForegroundColor Yellow
}

Write-Host "`n🔑 REQUIRED GITHUB SECRETS:" -ForegroundColor Cyan
Write-Host "  AZUREAPPSERVICE_CLIENTID_188E64413313450BA987CB17A2AB8FDB: $appId" -ForegroundColor White
Write-Host "  AZUREAPPSERVICE_TENANTID_C2DAC1E1B3D84CC99FED2841F7FB4839: $tenantId" -ForegroundColor White
Write-Host "  AZUREAPPSERVICE_SUBSCRIPTIONID_5E03C99C396E4E34A4B56AC7A1487628: $subscriptionId" -ForegroundColor White

Write-Host "`nPress any key to continue..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")