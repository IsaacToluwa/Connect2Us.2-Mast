# Quick Fix for Azure OIDC Authentication
# This script creates the missing federated identity credential

Write-Host "Azure OIDC Quick Fix" -ForegroundColor Green
Write-Host "===================" -ForegroundColor Green

Write-Host "`n🚨 IMPORTANT: This script will create the missing federated identity credential" -ForegroundColor Yellow
Write-Host "   that is causing your GitHub Actions to fail." -ForegroundColor Yellow

# Check Azure login
Write-Host "`n1. Checking Azure login..." -ForegroundColor Cyan
$azAccount = az account show 2>$null
if (!$azAccount) {
    Write-Host "✗ You are not logged into Azure" -ForegroundColor Red
    Write-Host "  Please run: az login" -ForegroundColor Yellow
    exit 1
}

$tenantId = az account show --query "tenantId" -o tsv
$subscriptionId = az account show --query "id" -o tsv

Write-Host "✓ Logged into Azure" -ForegroundColor Green
Write-Host "  Tenant: $tenantId" -ForegroundColor White
Write-Host "  Subscription: $subscriptionId" -ForegroundColor White

# Check if app exists
Write-Host "`n2. Checking for Connect2Us-GitHub-Actions app..." -ForegroundColor Cyan
$app = az ad app list --display-name "Connect2Us-GitHub-Actions" --query "[0]" -o json 2>$null
if (!$app -or $app -eq "null") {
    Write-Host "✗ Connect2Us-GitHub-Actions app not found" -ForegroundColor Red
    Write-Host "  Creating app registration..." -ForegroundColor Yellow
    
    # Create the app registration
    $appId = az ad app create --display-name "Connect2Us-GitHub-Actions" --query "appId" -o tsv
    if ($appId) {
        Write-Host "✓ Created app with ID: $appId" -ForegroundColor Green
    } else {
        Write-Host "✗ Failed to create app registration" -ForegroundColor Red
        exit 1
    }
} else {
    $appId = az ad app list --display-name "Connect2Us-GitHub-Actions" --query "[0].appId" -o tsv
    Write-Host "✓ Found existing app with ID: $appId" -ForegroundColor Green
}

$appObjectId = az ad app list --display-name "Connect2Us-GitHub-Actions" --query "[0].id" -o tsv

# Check federated credential
Write-Host "`n3. Checking federated credential..." -ForegroundColor Cyan
$ficExists = az ad app federated-credential list --id $appObjectId --query "[?name=='Connect2Us-GitHub-FIC']" -o tsv
if (!$ficExists) {
    Write-Host "✗ Federated credential not found" -ForegroundColor Red
    Write-Host "  Creating federated credential..." -ForegroundColor Yellow
    
    # Create federated credential using Azure CLI directly
    Write-Host "Creating federated credential..." -ForegroundColor Yellow
    $result = az ad app federated-credential create `
        --id $appObjectId `
        --name "Connect2Us-GitHub-FIC" `
        --issuer "https://token.actions.githubusercontent.com" `
        --subject "repo:IsaacToluwa/Connect2Us.2-Mast:environment:Production" `
        --description "GitHub Actions OIDC authentication for Connect2Us" `
        --audiences "api://AzureADTokenExchange" `
        --query "name" -o tsv 2>$null
    
    if ($result -eq "Connect2Us-GitHub-FIC") {
        Write-Host "✓ Created federated credential successfully" -ForegroundColor Green
    } else {
        Write-Host "✗ Failed to create federated credential" -ForegroundColor Red
        Write-Host "  Error: $result" -ForegroundColor Red
    }
} else {
    Write-Host "✓ Federated credential already exists" -ForegroundColor Green
}

# Check service principal
Write-Host "`n4. Checking service principal..." -ForegroundColor Cyan
$sp = az ad sp list --display-name "Connect2Us-GitHub-Actions" --query "[0]" -o json 2>$null
if (!$sp -or $sp -eq "null") {
    Write-Host "✗ Service principal not found" -ForegroundColor Red
    Write-Host "  Creating service principal..." -ForegroundColor Yellow
    
    $spId = az ad sp create --id $appId --query "id" -o tsv 2>$null
    if ($spId) {
        Write-Host "✓ Created service principal: $spId" -ForegroundColor Green
    } else {
        Write-Host "✗ Failed to create service principal" -ForegroundColor Red
    }
} else {
    Write-Host "✓ Service principal exists" -ForegroundColor Green
}

# Check web app permissions
Write-Host "`n5. Checking web app permissions..." -ForegroundColor Cyan
$webApp = az webapp list --query "[?name=='Connect2US']" -o json 2>$null
if ($webApp -and $webApp -ne "[]") {
    $webAppId = az webapp list --query "[?name=='Connect2US'].id" -o tsv
    Write-Host "✓ Found Connect2US web app" -ForegroundColor Green
    
    # Check role assignment
    $roleAssigned = az role assignment list --scope $webAppId --query "[?principalName=='Connect2Us-GitHub-Actions']" -o tsv
    if (!$roleAssigned) {
        Write-Host "✗ No role assignment found" -ForegroundColor Red
        Write-Host "  Assigning Website Contributor role..." -ForegroundColor Yellow
        
        $assignment = az role assignment create --assignee $appId --role "Website Contributor" --scope $webAppId --query "id" -o tsv 2>$null
        if ($assignment) {
            Write-Host "✓ Assigned Website Contributor role" -ForegroundColor Green
        } else {
            Write-Host "✗ Failed to assign role" -ForegroundColor Red
            Write-Host "  You may need to assign the role manually in Azure Portal" -ForegroundColor Yellow
        }
    } else {
        Write-Host "✓ Role assignment exists" -ForegroundColor Green
    }
} else {
    Write-Host "✗ Connect2US web app not found" -ForegroundColor Red
    Write-Host "  Please verify the web app name in Azure Portal" -ForegroundColor Yellow
}

# Final summary
Write-Host "`n✅ SETUP COMPLETE!" -ForegroundColor Green
Write-Host "==================" -ForegroundColor Green

Write-Host "`n📋 NEXT STEPS:" -ForegroundColor Cyan
Write-Host "1. Verify these secrets are set in your GitHub repository:" -ForegroundColor White
Write-Host "   AZUREAPPSERVICE_CLIENTID_188E64413313450BA987CB17A2AB8FDB = $appId" -ForegroundColor Yellow
Write-Host "   AZUREAPPSERVICE_TENANTID_C2DAC1E1B3D84CC99FED2841F7FB4839 = $tenantId" -ForegroundColor Yellow
Write-Host "   AZUREAPPSERVICE_SUBSCRIPTIONID_5E03C99C396E4E34A4B56AC7A1487628 = $subscriptionId" -ForegroundColor Yellow

Write-Host "`n2. Trigger a new GitHub Actions workflow run to test the authentication" -ForegroundColor White

Write-Host "`n3. If the authentication still fails, run troubleshoot-oidc.ps1 for detailed diagnostics" -ForegroundColor White

Write-Host "`nPress any key to continue..." -ForegroundColor Gray
$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null