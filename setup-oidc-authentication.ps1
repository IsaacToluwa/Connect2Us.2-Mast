# Azure OIDC Authentication Setup Guide for Connect2Us
# This guide helps resolve the federated identity authentication issue

Write-Host "Azure OIDC Authentication Setup Guide" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

Write-Host "`nPROBLEM IDENTIFIED:" -ForegroundColor Red
Write-Host "The Azure login is failing because no federated identity credential exists" -ForegroundColor Yellow
Write-Host "for the subject: 'repo:IsaacToluwa/Connect2Us.2-Mast:environment:Production'" -ForegroundColor Yellow

Write-Host "`nSOLUTION STEPS:" -ForegroundColor Green
Write-Host "=================" -ForegroundColor Green

Write-Host "`nStep 1: Create Azure App Registration" -ForegroundColor Yellow
Write-Host "Go to: https://portal.azure.com > Azure Active Directory > App registrations"
Write-Host "Click: 'New registration'"
Write-Host "Name: Connect2Us-GitHub-Actions"
Write-Host "Supported account types: Single tenant"
Write-Host "Redirect URI: Leave empty"

Write-Host "`nStep 2: Configure Federated Credentials" -ForegroundColor Yellow
Write-Host "After creating the app, go to: Certificates & secrets > Federated credentials"
Write-Host "Click: 'Add credential'"
Write-Host "Select: 'GitHub Actions' scenario"
Write-Host "Fill in the form:"
Write-Host "  - Organization: IsaacToluwa"
Write-Host "  - Repository: Connect2Us.2-Mast"
Write-Host "  - Entity type: Environment"
Write-Host "  - GitHub environment name: Production"
Write-Host "  - Name: Connect2Us-GitHub-FIC"

Write-Host "`nStep 3: Assign Permissions to Web App" -ForegroundColor Yellow
Write-Host "Go to your Connect2US web app resource"
Write-Host "Access control (IAM) > Add role assignment"
Write-Host "Role: Website Contributor"
Write-Host "Assign access to: User, group, or service principal"
Write-Host "Select: Connect2Us-GitHub-Actions"

Write-Host "`nStep 4: Update GitHub Secrets" -ForegroundColor Yellow
Write-Host "Go to your GitHub repository > Settings > Secrets and variables > Actions"
Write-Host "Add these secrets:"
Write-Host "  - AZURE_CLIENT_ID: (from your app registration)"
Write-Host "  - AZURE_TENANT_ID: (from Azure AD properties)"
Write-Host "  - AZURE_SUBSCRIPTION_ID: (from Azure subscriptions)"

Write-Host "`nStep 5: Simplify Secret Names (Optional)" -ForegroundColor Yellow
Write-Host "Your current workflow uses very long secret names. Consider updating to simpler names:"
Write-Host "Current: AZUREAPPSERVICE_CLIENTID_188E64413313450BA987CB17A2AB8FDB"
Write-Host "Better: AZURE_CLIENT_ID"

Write-Host "`nVERIFICATION:" -ForegroundColor Green
Write-Host "=============" -ForegroundColor Green
Write-Host "After setup, your GitHub Actions should be able to authenticate via OIDC."
Write-Host "The error should disappear and deployment should proceed."

Write-Host "`nTROUBLESHOOTING TIPS:" -ForegroundColor Red
Write-Host "=====================" -ForegroundColor Red
Write-Host "1. Ensure the federated credential subject exactly matches:"
Write-Host "   repo:IsaacToluwa/Connect2Us.2-Mast:environment:Production"
Write-Host "2. Check that the GitHub environment 'Production' exists in your repo"
Write-Host "3. Verify the Azure app has the correct permissions on the web app"
Write-Host "4. Make sure secrets are correctly set in GitHub repository settings"

Write-Host "`nPress any key to continue..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")