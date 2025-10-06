# Connect2Us Azure Resource Creation Script for Student Account
# Run this script in Azure Cloud Shell or with Azure CLI installed

# Variables - Update these values for your deployment
$resourceGroupName = "connect2us-student-rg"
$location = "eastus"  # Change to your preferred region
$appServicePlanName = "connect2us-student-plan"
$webAppName = "connect2us-student-app-$(Get-Random -Minimum 1000 -Maximum 9999)"
$sqlServerName = "connect2us-student-sql-$(Get-Random -Minimum 1000 -Maximum 9999)"
$sqlDatabaseName = "Connect2UsDB"
$storageAccountName = "connect2usstudent$(Get-Random -Minimum 1000 -Maximum 9999)"

# SQL Admin credentials (CHANGE THESE!)
$sqlAdminLogin = "sqladmin"
$sqlAdminPassword = "YourStrongPassword123!"

Write-Host "🚀 Starting Azure resource creation for Connect2Us..." -ForegroundColor Green
Write-Host "Resource Group: $resourceGroupName" -ForegroundColor Yellow
Write-Host "Web App: $webAppName" -ForegroundColor Yellow
Write-Host "SQL Server: $sqlServerName" -ForegroundColor Yellow
Write-Host "Storage Account: $storageAccountName" -ForegroundColor Yellow

# Login to Azure (if not already logged in)
# Connect-AzAccount

# Create Resource Group
Write-Host "📁 Creating Resource Group..." -ForegroundColor Cyan
New-AzResourceGroup -Name $resourceGroupName -Location $location

# Create App Service Plan (Free Tier)
Write-Host "🌐 Creating App Service Plan (Free Tier)..." -ForegroundColor Cyan
New-AzAppServicePlan -Name $appServicePlanName -Location $location -ResourceGroupName $resourceGroupName -Tier Free -WorkerSize Small

# Create Web App
Write-Host "🌐 Creating Web App..." -ForegroundColor Cyan
New-AzWebApp -Name $webAppName -Location $location -AppServicePlan $appServicePlanName -ResourceGroupName $resourceGroupName

# Create SQL Server
Write-Host "🗄️ Creating SQL Server..." -ForegroundColor Cyan
$sqlServer = New-AzSqlServer -ResourceGroupName $resourceGroupName -ServerName $sqlServerName -Location $location -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $sqlAdminLogin, $(ConvertTo-SecureString -String $sqlAdminPassword -AsPlainText -Force))

# Create SQL Database (Basic Tier for students)
Write-Host "🗄️ Creating SQL Database..." -ForegroundColor Cyan
New-AzSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $sqlServerName -DatabaseName $sqlDatabaseName -RequestedServiceObjectiveName "Basic"

# Create Storage Account
Write-Host "💾 Creating Storage Account..." -ForegroundColor Cyan
$storageAccount = New-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -Location $location -SkuName Standard_LRS

# Configure SQL Server Firewall (Allow Azure services)
Write-Host "🔥 Configuring SQL Firewall..." -ForegroundColor Cyan
New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName -ServerName $sqlServerName -FirewallRuleName "AllowAzureServices" -StartIpAddress "0.0.0.0" -EndIpAddress "0.0.0.0"

# Get connection string
$sqlConnectionString = "Server=tcp:$sqlServerName.database.windows.net,1433;Initial Catalog=$sqlDatabaseName;Persist Security Info=False;User ID=$sqlAdminLogin;Password=$sqlAdminPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout 30;"

# Configure Web App Settings
Write-Host "⚙️ Configuring Web App Settings..." -ForegroundColor Cyan
$webApp = Get-AzWebApp -ResourceGroupName $resourceGroupName -Name $webAppName

# Set connection string
Set-AzWebApp -ResourceGroupName $resourceGroupName -Name $webAppName -ConnectionStrings @{ 
    "DefaultConnection" = New-Object Microsoft.Azure.Management.WebSites.Models.ConnStringInfo -Property @{
        ConnectionString = $sqlConnectionString
        Type = "SQLAzure"
    }
}

# Set app settings
Set-AzWebApp -ResourceGroupName $resourceGroupName -Name $webAppName -AppSettings @{
    "ASPNETCORE_ENVIRONMENT" = "Production"
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
    "StripePublishableKey" = "YOUR_PRODUCTION_STRIPE_KEY"
    "StripeSecretKey" = "YOUR_PRODUCTION_STRIPE_SECRET"
}

Write-Host "✅ Azure resources created successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 DEPLOYMENT SUMMARY" -ForegroundColor Yellow
Write-Host "=====================" -ForegroundColor Yellow
Write-Host "Resource Group: $resourceGroupName" -ForegroundColor White
Write-Host "Web App URL: https://$webAppName.azurewebsites.net" -ForegroundColor White
Write-Host "SQL Server: $sqlServerName.database.windows.net" -ForegroundColor White
Write-Host "SQL Database: $sqlDatabaseName" -ForegroundColor White
Write-Host "Storage Account: $storageAccountName" -ForegroundColor White
Write-Host ""
Write-Host "🔑 CONNECTION STRING:" -ForegroundColor Yellow
Write-Host $sqlConnectionString -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️ IMPORTANT NOTES:" -ForegroundColor Red
Write-Host "1. Update your Web.Release.config with the connection string above"
Write-Host "2. Replace Stripe keys with your production keys"
Write-Host "3. Deploy your application using Visual Studio or GitHub Actions"
Write-Host "4. Run database migrations after deployment"
Write-Host "5. Monitor your usage to stay within free tier limits"
Write-Host ""
Write-Host "🎯 NEXT STEPS:" -ForegroundColor Green
Write-Host "1. Deploy your application using Visual Studio"
Write-Host "2. Test all functionality on the live site"
Write-Host "3. Set up monitoring and alerts"
Write-Host "4. Configure custom domain (optional)"

# Save deployment information to file
$deploymentInfo = @{
    ResourceGroup = $resourceGroupName
    WebAppName = $webAppName
    WebAppUrl = "https://$webAppName.azurewebsites.net"
    SqlServerName = $sqlServerName
    SqlDatabaseName = $sqlDatabaseName
    SqlConnectionString = $sqlConnectionString
    StorageAccountName = $storageAccountName
    CreatedDate = Get-Date
} | ConvertTo-Json

$deploymentInfo | Out-File -FilePath "azure-deployment-info.json" -Encoding UTF8
Write-Host ""
Write-Host "💾 Deployment information saved to: azure-deployment-info.json" -ForegroundColor Green