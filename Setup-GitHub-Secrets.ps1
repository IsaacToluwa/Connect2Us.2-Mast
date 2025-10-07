# GitHub Secrets Setup Script
# This script helps you set up the required GitHub secrets for Azure deployment
# Since your GitHub and Azure accounts are different, you'll need to manually configure these

Write-Host "=== GITHUB SECRETS SETUP GUIDE ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "Since your GitHub and Azure accounts are different, you'll need to manually set up these secrets:" -ForegroundColor Yellow
Write-Host ""

# Required GitHub Secrets
$secrets = @{
    "AZURE_SUBSCRIPTION_ID" = @{
        Description = "Your Azure subscription ID"
        HowToGet = "Azure Portal > Subscriptions > Copy the Subscription ID"
        Example = "12345678-1234-1234-1234-123456789012"
    }
    "AZURE_RESOURCE_GROUP" = @{
        Description = "Name of your Azure resource group"
        HowToGet = "Azure Portal > Resource Groups > Select your group"
        Example = "connect2us-rg"
    }
    "AZURE_SQL_CONNECTION_STRING" = @{
        Description = "Connection string for Azure SQL Database"
        HowToGet = "Azure Portal > SQL Databases > Your DB > Connection strings"
        Example = "Server=tcp:your-server.database.windows.net,1433;Database=Connect2US;User ID=sqladmin;Password=your-password;Encrypt=true;TrustServerCertificate=false;"
    }
    "STRIPE_PUBLISHABLE_KEY" = @{
        Description = "Stripe publishable key for payments"
        HowToGet = "Stripe Dashboard > Developers > API Keys"
        Example = "pk_test_YOUR_STRIPE_PUBLISHABLE_KEY_HERE"
    }
    "STRIPE_SECRET_KEY" = @{
        Description = "Stripe secret key for payments"
        HowToGet = "Stripe Dashboard > Developers > API Keys"
        Example = "sk_test_YOUR_STRIPE_SECRET_KEY_HERE"
    }
}

Write-Host "REQUIRED SECRETS:" -ForegroundColor Green
Write-Host ""

foreach ($secret in $secrets.GetEnumerator()) {
    Write-Host "🔑 $($secret.Key)" -ForegroundColor Cyan
    Write-Host "   Description: $($secret.Value.Description)" -ForegroundColor White
    Write-Host "   How to get: $($secret.Value.HowToGet)" -ForegroundColor Yellow
    Write-Host "   Example: $($secret.Value.Example)" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "=== STEP-BY-STEP INSTRUCTIONS ===" -ForegroundColor Yellow
Write-Host ""

Write-Host "1. Get your Azure information:" -ForegroundColor Green
Write-Host "   • Go to https://portal.azure.com" -ForegroundColor White
Write-Host "   • Navigate to your resource group" -ForegroundColor White
Write-Host "   • Copy the resource group name and subscription ID" -ForegroundColor White
Write-Host ""

Write-Host "2. Get your SQL connection string:" -ForegroundColor Green
Write-Host "   • Go to Azure Portal > SQL Databases" -ForegroundColor White
Write-Host "   • Select your Connect2US database" -ForegroundColor White
Write-Host "   • Go to 'Connection strings' section" -ForegroundColor White
Write-Host "   • Copy the ADO.NET connection string" -ForegroundColor White
Write-Host ""

Write-Host "3. Set up GitHub Secrets:" -ForegroundColor Green
Write-Host "   • Go to your GitHub repository" -ForegroundColor White
Write-Host "   • Settings > Secrets and variables > Actions" -ForegroundColor White
Write-Host "   • Click 'New repository secret'" -ForegroundColor White
Write-Host "   • Add each secret with its corresponding value" -ForegroundColor White
Write-Host ""

Write-Host "4. Add these secrets to GitHub:" -ForegroundColor Yellow
Write-Host ""

foreach ($secret in $secrets.GetEnumerator()) {
    Write-Host "   • $($secret.Key)" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "=== OPTIONAL SECRETS ===" -ForegroundColor Yellow
Write-Host ""

$optionalSecrets = @{
    "AZURE_TENANT_ID" = @{
        Description = "Azure Active Directory Tenant ID"
        HowToGet = "Azure Portal > Azure Active Directory > Properties > Tenant ID"
    }
    "AZURE_CLIENT_ID" = @{
        Description = "Service Principal Client ID"
        HowToGet = "Azure Portal > App registrations > Your app > Application ID"
    }
    "AZURE_CLIENT_SECRET" = @{
        Description = "Service Principal Client Secret"
        HowToGet = "Azure Portal > App registrations > Your app > Certificates & secrets"
    }
}

foreach ($secret in $optionalSecrets.GetEnumerator()) {
    Write-Host "🔑 $($secret.Key) (Optional)" -ForegroundColor Gray
    Write-Host "   Description: $($secret.Value.Description)" -ForegroundColor Gray
    Write-Host "   How to get: $($secret.Value.HowToGet)" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "=== VERIFICATION ===" -ForegroundColor Yellow
Write-Host ""
Write-Host "After setting up the secrets, you can verify they're working by:" -ForegroundColor White
Write-Host "1. Creating a test deployment" -ForegroundColor White
Write-Host "2. Checking the GitHub Actions logs" -ForegroundColor White
Write-Host "3. Monitoring the Azure deployment" -ForegroundColor White
Write-Host ""

Write-Host "=== TROUBLESHOOTING ===" -ForegroundColor Red
Write-Host ""
Write-Host "If deployment fails, check:" -ForegroundColor Yellow
Write-Host "• Secret values are correct (no typos)" -ForegroundColor White
Write-Host "• Azure resources exist and are properly configured" -ForegroundColor White
Write-Host "• GitHub repository has access to Azure (if using service principal)" -ForegroundColor White
Write-Host "• SQL firewall rules allow Azure services" -ForegroundColor White
Write-Host ""

Write-Host "=== SCRIPT COMPLETE ===" -ForegroundColor Cyan
Write-Host "Follow the steps above to set up your GitHub secrets for Azure deployment!" -ForegroundColor Green