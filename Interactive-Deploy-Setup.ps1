# Interactive Azure Deployment Setup
Write-Host "=== INTERACTIVE AZURE DEPLOYMENT SETUP ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check current configuration
Write-Host "🔍 STEP 1: Checking current configuration..." -ForegroundColor Yellow
Write-Host ""

# Check Web.config current state
if (Test-Path "Web.config") {
    $webConfig = Get-Content "Web.config" -Raw
    
    Write-Host "Current Web.config status:" -ForegroundColor White
    
    if ($webConfig -match "localhost") {
        Write-Host "  ⚠ Localhost references found" -ForegroundColor Yellow
    } else {
        Write-Host "  ✓ No localhost references" -ForegroundColor Green
    }
    
    if ($webConfig -match "LocalDb") {
        Write-Host "  ⚠ LocalDB references found" -ForegroundColor Yellow
    } else {
        Write-Host "  ✓ No LocalDB references" -ForegroundColor Green
    }
    
    if ($webConfig -match "AzureConnection") {
        Write-Host "  ✓ Azure connection string template found" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ Azure connection string template missing" -ForegroundColor Yellow
    }
}

Write-Host ""

# Step 2: Azure Resource Information
Write-Host "🔧 STEP 2: Azure Resource Configuration" -ForegroundColor Yellow
Write-Host ""

Write-Host "Do you already have Azure resources created?" -ForegroundColor White
Write-Host "  1. Yes, I have SQL Server and Database already set up" -ForegroundColor Cyan
Write-Host "  2. No, I need to create them first" -ForegroundColor Cyan
Write-Host "  3. I'm not sure, let me check" -ForegroundColor Cyan
Write-Host ""

$choice = Read-Host "Enter your choice (1-3)"

switch ($choice) {
    "1" {
        Write-Host "Great! Let's configure your existing Azure resources." -ForegroundColor Green
        
        # Get Azure SQL details
        Write-Host ""
        Write-Host "Please provide your Azure SQL Server details:" -ForegroundColor Yellow
        
        $sqlServer = Read-Host "Azure SQL Server name (e.g., myserver.database.windows.net)"
        $sqlDatabase = Read-Host "Database name (default: Connect2US)"
        $sqlUser = Read-Host "SQL Admin username"
        $sqlPassword = Read-Host "SQL Admin password" -AsSecureString
        
        # Convert secure string to plain text for connection string
        $sqlPasswordPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($sqlPassword))
        
        if ([string]::IsNullOrEmpty($sqlDatabase)) {
            $sqlDatabase = "Connect2US"
        }
        
        Write-Host ""
        Write-Host "Configuration summary:" -ForegroundColor Cyan
        Write-Host "  SQL Server: $sqlServer" -ForegroundColor White
        Write-Host "  Database: $sqlDatabase" -ForegroundColor White
        Write-Host "  Username: $sqlUser" -ForegroundColor White
        Write-Host ""
        
        $confirm = Read-Host "Is this correct? (Y/N)"
        
        if ($confirm -eq "Y" -or $confirm -eq "y") {
            # Run the deployment preparation script
            Write-Host "Running deployment preparation..." -ForegroundColor Green
            
            try {
                & ".\Deploy-Azure-Ready.ps1" -AzureSqlServer $sqlServer -AzureSqlDatabase $sqlDatabase -AzureSqlUser $sqlUser -AzureSqlPassword $sqlPasswordPlain
                
                Write-Host ""
                Write-Host "✓ Deployment preparation completed!" -ForegroundColor Green
                Write-Host ""
                Write-Host "Next steps:" -ForegroundColor Yellow
                Write-Host "1. Review the updated Web.config file" -ForegroundColor White
                Write-Host "2. Set up GitHub secrets using: .\Setup-GitHub-Secrets.ps1" -ForegroundColor White
                Write-Host "3. Deploy using GitHub Actions or Azure portal" -ForegroundColor White
                
            } catch {
                Write-Host "✗ Error during deployment preparation: $_" -ForegroundColor Red
                Write-Host "Check the error message above and try again." -ForegroundColor Yellow
            }
        } else {
            Write-Host "Setup cancelled. Run the script again when you're ready." -ForegroundColor Yellow
        }
    }
    "2" {
        Write-Host ""
        Write-Host "Let's create your Azure resources first!" -ForegroundColor Green
        Write-Host ""
        Write-Host "I can help you create the necessary Azure resources." -ForegroundColor White
        Write-Host "You have a few options:" -ForegroundColor White
        Write-Host ""
        Write-Host "A. Use Azure Portal (Recommended for beginners)" -ForegroundColor Cyan
        Write-Host "   1. Go to https://portal.azure.com" -ForegroundColor White
        Write-Host "   2. Create a Resource Group" -ForegroundColor White
        Write-Host "   3. Create SQL Server and Database" -ForegroundColor White
        Write-Host "   4. Come back here with the details" -ForegroundColor White
        Write-Host ""
        Write-Host "B. Use Azure CLI (Advanced)" -ForegroundColor Cyan
        Write-Host "   I can create a script to automate resource creation" -ForegroundColor White
        Write-Host ""
        
        $createChoice = Read-Host "Which option do you prefer? (A/B)"
        
        if ($createChoice -eq "A" -or $createChoice -eq "a") {
            Write-Host ""
            Write-Host "Perfect! Here's what you need to create:" -ForegroundColor Green
            Write-Host ""
            Write-Host "📋 Azure Resources Checklist:" -ForegroundColor Yellow
            Write-Host "  1. Resource Group (name: connect2us-rg)" -ForegroundColor White
            Write-Host "  2. SQL Server (name: connect2us-server)" -ForegroundColor White
            Write-Host "  3. SQL Database (name: Connect2US)" -ForegroundColor White
            Write-Host "  4. App Service Plan (name: connect2us-plan)" -ForegroundColor White
            Write-Host "  5. Web App (name: connect2us-app)" -ForegroundColor White
            Write-Host ""
            Write-Host "After creating these, come back and run this script again with option 1." -ForegroundColor Green
            
        } elseif ($createChoice -eq "B" -or $createChoice -eq "b") {
            Write-Host ""
            Write-Host "I can create an Azure resource creation script for you." -ForegroundColor Green
            $createScript = Read-Host "Would you like me to create the resource creation script? (Y/N)"
            
            if ($createScript -eq "Y" -or $createScript -eq "y") {
                Write-Host "Creating Azure resource creation script..." -ForegroundColor Yellow
                
                # Create a simple Azure resource creation script
                $resourceScript = @"
# Azure Resource Creation Script
# Run this after logging into Azure: Connect-AzAccount

param(
    [string]\$ResourceGroupName = "connect2us-rg",
    [string]\$Location = "eastus",
    [string]\$SqlServerName = "connect2us-server",
    [string]\$DatabaseName = "Connect2US",
    [string]\$AppServicePlanName = "connect2us-plan",
    [string]\$WebAppName = "connect2us-app",
    [string]\$SqlAdminUser = "sqladmin",
    [securestring]\$SqlAdminPassword
)

Write-Host "Creating Azure resources..." -ForegroundColor Green

# Create Resource Group
New-AzResourceGroup -Name \$ResourceGroupName -Location \$Location

# Create SQL Server
New-AzSqlServer -ResourceGroupName \$ResourceGroupName `
    -ServerName \$SqlServerName `
    -Location \$Location `
    -SqlAdministratorCredentials (New-Object System.Management.Automation.PSCredential(\$SqlAdminUser, \$SqlAdminPassword))

# Create SQL Database
New-AzSqlDatabase -ResourceGroupName \$ResourceGroupName `
    -ServerName \$SqlServerName `
    -DatabaseName \$DatabaseName `
    -RequestedServiceObjectiveName "Basic"

# Allow Azure services access to SQL
New-AzSqlServerFirewallRule -ResourceGroupName \$ResourceGroupName `
    -ServerName \$SqlServerName `
    -FirewallRuleName "AllowAzureServices" `
    -StartIpAddress "0.0.0.0" -EndIpAddress "0.0.0.0"

# Create App Service Plan
New-AzAppServicePlan -ResourceGroupName \$ResourceGroupName `
    -Name \$AppServicePlanName `
    -Location \$Location `
    -Tier "Basic" -WorkerSize "Small"

# Create Web App
New-AzWebApp -ResourceGroupName \$ResourceGroupName `
    -Name \$WebAppName `
    -Location \$Location `
    -AppServicePlan \$AppServicePlanName

Write-Host "Azure resources created successfully!" -ForegroundColor Green
Write-Host "SQL Server: \$SqlServerName.database.windows.net" -ForegroundColor Cyan
Write-Host "Database: \$DatabaseName" -ForegroundColor Cyan
Write-Host "Web App: https://\$WebAppName.azurewebsites.net" -ForegroundColor Cyan
"@
                
                Set-Content -Path "Create-AzureResources-Interactive.ps1" -Value $resourceScript
                Write-Host "✓ Resource creation script created: Create-AzureResources-Interactive.ps1" -ForegroundColor Green
                Write-Host ""
                Write-Host "To use this script:" -ForegroundColor Yellow
                Write-Host "1. Run: Connect-AzAccount" -ForegroundColor White
                Write-Host "2. Run: .\Create-AzureResources-Interactive.ps1" -ForegroundColor White
                Write-Host "3. Come back here with the SQL details" -ForegroundColor White
            }
        }
    }
    "3" {
        Write-Host "Let me help you check your Azure setup!" -ForegroundColor Green
        Write-Host ""
        
        # Check if Azure PowerShell module is available
        if (Get-Module -ListAvailable -Name Az) {
            Write-Host "✓ Azure PowerShell module is installed" -ForegroundColor Green
            
            try {
                $context = Get-AzContext
                if ($context) {
                    Write-Host "✓ You are logged into Azure" -ForegroundColor Green
                    Write-Host "  Subscription: $($context.Subscription.Name)" -ForegroundColor Cyan
                    Write-Host "  Tenant: $($context.Tenant.Id)" -ForegroundColor Cyan
                    
                    Write-Host ""
                    Write-Host "Your resource groups:" -ForegroundColor Yellow
                    $resourceGroups = Get-AzResourceGroup
                    if ($resourceGroups) {
                        foreach ($rg in $resourceGroups) {
                            Write-Host "  - $($rg.ResourceGroupName) (Location: $($rg.Location))" -ForegroundColor White
                        }
                    } else {
                        Write-Host "  No resource groups found" -ForegroundColor Yellow
                    }
                } else {
                    Write-Host "⚠ You are not logged into Azure" -ForegroundColor Yellow
                    Write-Host "Run: Connect-AzAccount to login" -ForegroundColor White
                }
            } catch {
                Write-Host "⚠ Could not check Azure context: $_" -ForegroundColor Yellow
            }
        } else {
            Write-Host "⚠ Azure PowerShell module is not installed" -ForegroundColor Yellow
            Write-Host "You can still proceed with manual setup" -ForegroundColor White
        }
        
        Write-Host ""
        Write-Host "After checking your Azure setup, run this script again with option 1 or 2." -ForegroundColor Green
    }
    default {
        Write-Host "Invalid choice. Please run the script again." -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== SETUP COMPLETE ===" -ForegroundColor Cyan