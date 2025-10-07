# Quick Azure Deployment Setup
Write-Host "=== AZURE DEPLOYMENT SETUP ===" -ForegroundColor Cyan
Write-Host ""

# Check current Web.config status
Write-Host "🔍 Current Configuration Status:" -ForegroundColor Yellow
if (Test-Path "Web.config") {
    $content = Get-Content "Web.config" -Raw
    
    if ($content -match "localhost") {
        Write-Host "  ⚠ Localhost references found - NEEDS UPDATE" -ForegroundColor Yellow
    } else {
        Write-Host "  ✓ No localhost references" -ForegroundColor Green
    }
    
    if ($content -match "LocalDb") {
        Write-Host "  ⚠ LocalDB references found - NEEDS UPDATE" -ForegroundColor Yellow
    } else {
        Write-Host "  ✓ No LocalDB references" -ForegroundColor Green
    }
}
Write-Host ""

# Simple setup options
Write-Host "Choose your setup method:" -ForegroundColor Yellow
Write-Host "1. I have Azure SQL details ready" -ForegroundColor Green
Write-Host "2. Show me what Azure resources I need" -ForegroundColor Cyan
Write-Host "3. Test with demo connection string" -ForegroundColor Magenta
Write-Host ""

$choice = Read-Host "Enter your choice (1-3)"

switch ($choice) {
    "1" {
        Write-Host ""
        Write-Host "Great! Let's configure your Azure SQL connection." -ForegroundColor Green
        Write-Host ""
        
        # Get connection details
        $server = Read-Host "Azure SQL Server (format: yourserver.database.windows.net)"
        $database = Read-Host "Database name (press Enter for Connect2US)"
        $username = Read-Host "SQL Admin username"
        $password = Read-Host "SQL Admin password"
        
        if ([string]::IsNullOrEmpty($database)) {
            $database = "Connect2US"
        }
        
        Write-Host ""
        Write-Host "Configuration Summary:" -ForegroundColor Cyan
        Write-Host "Server: $server" -ForegroundColor White
        Write-Host "Database: $database" -ForegroundColor White
        Write-Host "Username: $username" -ForegroundColor White
        Write-Host ""
        
        $confirm = Read-Host "Proceed with this configuration? (Y/N)"
        
        if ($confirm -eq "Y" -or $confirm -eq "y") {
            Write-Host "Running deployment preparation..." -ForegroundColor Yellow
            
            # Create a simple parameter file for the main script
            $params = @{
                AzureSqlServer = $server
                AzureSqlDatabase = $database
                AzureSqlUser = $username
                AzureSqlPassword = $password
                Environment = "Production"
            }
            
            # Convert to JSON for easy passing
            $params | ConvertTo-Json | Set-Content "deploy-params.json"
            
            Write-Host "✓ Parameters saved to deploy-params.json" -ForegroundColor Green
            Write-Host ""
            Write-Host "Now running the main deployment preparation script..." -ForegroundColor Yellow
            
            try {
                & ".\Deploy-Azure-Ready.ps1" -AzureSqlServer $server -AzureSqlDatabase $database -AzureSqlUser $username -AzureSqlPassword $password
                
                if (Test-Path "deploy-params.json") {
                    Remove-Item "deploy-params.json" -Force
                }
                
                Write-Host ""
                Write-Host "🎉 DEPLOYMENT PREPARATION COMPLETE!" -ForegroundColor Green
                Write-Host ""
                Write-Host "Next steps:" -ForegroundColor Yellow
                Write-Host "1. Check the updated Web.config file" -ForegroundColor White
                Write-Host "2. Set up GitHub secrets: .\Setup-GitHub-Secrets.ps1" -ForegroundColor White
                Write-Host "3. Deploy to Azure using GitHub Actions" -ForegroundColor White
                
            } catch {
                Write-Host "❌ Error during preparation: $_" -ForegroundColor Red
                Write-Host "Check the error above and try again." -ForegroundColor Yellow
            }
        }
    }
    "2" {
        Write-Host ""
        Write-Host "📋 AZURE RESOURCES YOU NEED:" -ForegroundColor Green
        Write-Host ""
        Write-Host "Required Azure Resources:" -ForegroundColor Yellow
        Write-Host "  1. Resource Group (e.g., connect2us-rg)" -ForegroundColor White
        Write-Host "  2. SQL Server (e.g., connect2us-server)" -ForegroundColor White
        Write-Host "  3. SQL Database (e.g., Connect2US)" -ForegroundColor White
        Write-Host "  4. App Service Plan (Windows, .NET Framework)" -ForegroundColor White
        Write-Host "  5. Web App (ASP.NET 4.7.2)" -ForegroundColor White
        Write-Host ""
        Write-Host "To create these resources:" -ForegroundColor Cyan
        Write-Host "  • Go to https://portal.azure.com" -ForegroundColor White
        Write-Host "  • Click 'Create a resource'" -ForegroundColor White
        Write-Host "  • Search for and create each resource type" -ForegroundColor White
        Write-Host ""
        Write-Host "After creating resources, run this script again and choose option 1." -ForegroundColor Green
    }
    "3" {
        Write-Host ""
        Write-Host "🧪 TESTING WITH DEMO CONNECTION STRING" -ForegroundColor Magenta
        Write-Host ""
        Write-Host "This will use a demo configuration for testing purposes." -ForegroundColor Yellow
        Write-Host "You'll need to update with your real Azure details before production deployment." -ForegroundColor Yellow
        Write-Host ""
        
        $demoServer = "demo-server.database.windows.net"
        $demoDatabase = "Connect2US"
        $demoUsername = "sqladmin"
        $demoPassword = "DemoPassword123!"
        
        Write-Host "Demo Configuration:" -ForegroundColor Cyan
        Write-Host "Server: $demoServer" -ForegroundColor White
        Write-Host "Database: $demoDatabase" -ForegroundColor White
        Write-Host "Username: $demoUsername" -ForegroundColor White
        Write-Host "Password: $demoPassword" -ForegroundColor White
        Write-Host ""
        
        $confirm = Read-Host "Proceed with demo setup? (Y/N)"
        
        if ($confirm -eq "Y" -or $confirm -eq "y") {
            Write-Host "Running demo deployment preparation..." -ForegroundColor Yellow
            
            try {
                & ".\Deploy-Azure-Ready.ps1" -AzureSqlServer $demoServer -AzureSqlDatabase $demoDatabase -AzureSqlUser $demoUsername -AzureSqlPassword $demoPassword
                
                Write-Host ""
                Write-Host "✅ DEMO SETUP COMPLETE!" -ForegroundColor Green
                Write-Host ""
                Write-Host "Your Web.config has been updated for Azure deployment format." -ForegroundColor White
                Write-Host "Remember to update with your real Azure SQL details before production!" -ForegroundColor Yellow
                Write-Host ""
                Write-Host "Next steps:" -ForegroundColor Yellow
                Write-Host "1. Review Web.config changes" -ForegroundColor White
                Write-Host "2. Replace demo connection with real Azure details" -ForegroundColor White
                Write-Host "3. Set up GitHub secrets" -ForegroundColor White
                
            } catch {
                Write-Host "❌ Error during demo setup: $_" -ForegroundColor Red
            }
        }
    }
    default {
        Write-Host "Invalid choice. Please run the script again." -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== SETUP COMPLETE ===" -ForegroundColor Cyan