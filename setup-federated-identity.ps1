# Azure Federated Identity Setup Script for GitHub Actions
# This script helps configure OIDC authentication between GitHub and Azure

Write-Host "Azure Federated Identity Setup for GitHub Actions" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green

# Configuration
$githubRepo = "IsaacToluwa/Connect2Us.2-Mast"
$azureAppName = "Connect2Us-GitHub-Actions"
$environment = "Production"

Write-Host "`nConfiguration:" -ForegroundColor Yellow
Write-Host "GitHub Repository: $githubRepo" -ForegroundColor White
Write-Host "Environment: $environment" -ForegroundColor White
Write-Host "Azure App Name: $azureAppName" -ForegroundColor White

Write-Host "`nStep-by-Step Setup Instructions:" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green

Write-Host "`n1. Create an Azure App Registration:" -ForegroundColor Yellow
Write-Host "   az ad app create --display-name '$azureAppName' --query 'appId' -o tsv" -ForegroundColor Cyan

Write-Host "`n2. Create a Service Principal:" -ForegroundColor Yellow
Write-Host "   az ad sp create --id <APP_ID_FROM_STEP_1> --query 'id' -o tsv" -ForegroundColor Cyan

Write-Host "`n3. Assign Contributor Role to your Azure Web App:" -ForegroundColor Yellow
Write-Host "   az role assignment create --assignee <SERVICE_PRINCIPAL_ID> --role 'Website Contributor' --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP>/providers/Microsoft.Web/sites/Connect2US" -ForegroundColor Cyan

Write-Host "`n4. Create Federated Identity Credential:" -ForegroundColor Yellow
Write-Host "   az ad app federated-credential create --id <APP_ID> --parameters '" -ForegroundColor Cyan
Write-Host "   {'" -ForegroundColor Cyan
Write-Host "     \"name\": \"Connect2Us-GitHub-FIC\"," -ForegroundColor Cyan
Write-Host "     \"issuer\": \"https://token.actions.githubusercontent.com\"," -ForegroundColor Cyan
Write-Host "     \"subject\": \"repo:$githubRepo:environment:$environment\"," -ForegroundColor Cyan
Write-Host "     \"description\": \"GitHub Actions OIDC for Connect2Us deployment\"," -ForegroundColor Cyan
Write-Host "     \"audiences\": [\"api://AzureADTokenExchange\"]" -ForegroundColor Cyan
Write-Host "   }'}" -ForegroundColor Cyan

Write-Host "`n5. Update GitHub Secrets:" -ForegroundColor Yellow
Write-Host "   - AZURE_CLIENT_ID: <APP_ID_FROM_STEP_1>" -ForegroundColor White
Write-Host "   - AZURE_TENANT_ID: <TENANT_ID>" -ForegroundColor White
Write-Host "   - AZURE_SUBSCRIPTION_ID: <SUBSCRIPTION_ID>" -ForegroundColor White

Write-Host "`nRequired Information:" -ForegroundColor Red
Write-Host "======================" -ForegroundColor Red

Write-Host "`nPlease provide the following information to proceed:" -ForegroundColor Yellow
Write-Host "- Azure Tenant ID (from Azure Portal > Azure Active Directory > Properties)" -ForegroundColor White
Write-Host "- Azure Subscription ID (from Azure Portal > Subscriptions)" -ForegroundColor White
Write-Host "- Azure Resource Group name where Connect2US web app is located" -ForegroundColor White

Write-Host "`nAlternative: Manual Setup in Azure Portal" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

Write-Host "`n1. Go to Azure Portal > Azure Active Directory > App registrations" -ForegroundColor White
Write-Host "2. Click 'New registration' and create app named '$azureAppName'" -ForegroundColor White
Write-Host "3. Go to the app > Certificates & secrets > Federated credentials" -ForegroundColor White
Write-Host "4. Click 'Add credential' and configure:" -ForegroundColor White
Write-Host "   - Federated credential scenario: GitHub Actions" -ForegroundColor White
Write-Host "   - Organization: IsaacToluwa" -ForegroundColor White
Write-Host "   - Repository: Connect2Us.2-Mast" -ForegroundColor White
Write-Host "   - Entity: Environment" -ForegroundColor White
Write-Host "   - GitHub environment name: Production" -ForegroundColor White
Write-Host "   - Name: Connect2Us-GitHub-FIC" -ForegroundColor White

Write-Host "`nAfter setup, update your GitHub repository secrets with the App ID, Tenant ID, and Subscription ID." -ForegroundColor Yellow

Write-Host "`nPress any key to continue..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")