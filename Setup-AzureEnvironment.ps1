# Connect2Us Azure Environment Setup Script
# This script sets up both staging and production environments for Connect2Us

param(
    [string]$ResourceGroupName = "connect2us-rg",
    [string]$Location = "eastus",
    [string]$BaseAppName = "connect2us-app",
    [string]$SqlAdminUser = "connect_admin",
    [string]$SqlAdminPassword = "Test@123",
    [string]$SubscriptionId = ""
)

# Import Azure module
Import-Module Az -ErrorAction SilentlyContinue

# Function to write colored output
function Write-Status {
    param(
        [string]$Message,
        [string]$Status = "INFO"
    )
    
    $colors = @{
        "INFO" = "White"
        "SUCCESS" = "Green"
        "WARNING" = "Yellow"
        "ERROR" = "Red"
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Status] $Message" -ForegroundColor $colors[$Status]
}

# Check if user is logged in
function Test-AzureLogin {
    try {
        $context = Get-AzContext
        return ($null -ne $context)
    }
    catch {
        return $false
    }
}

# Main execution
try {
    Write-Status "Starting Connect2Us Azure environment setup" "INFO"
    
    # Check Azure login
    if (-not (Test-AzureLogin)) {
        Write-Status "Please login to Azure first using: Connect-AzAccount" "ERROR"
        Write-Status "After logging in, run this script again." "ERROR"
        exit 1
    }

    # Set subscription if provided
    if ($SubscriptionId) {
        Set-AzContext -SubscriptionId $SubscriptionId
        Write-Status "Using subscription: $SubscriptionId" "INFO"
    }

    # Create Production Environment
    Write-Status "=== Creating Production Environment ===" "INFO"
    $productionParams = @{
        ResourceGroupName = $ResourceGroupName
        Location = $Location
        AppServiceName = $BaseAppName
        SqlServerName = "$($BaseAppName.Replace('-', ''))server"
        SqlDatabaseName = "Connect2US"
        SqlAdminUser = $SqlAdminUser
        SqlAdminPassword = $SqlAdminPassword
        SubscriptionId = $SubscriptionId
    }

    Write-Status "Running Create-AzureResources-PS.ps1 for Production..." "INFO"
    & ".\Create-AzureResources-PS.ps1" @productionParams

    if ($LASTEXITCODE -ne 0) {
        Write-Status "Production environment creation failed" "ERROR"
        exit 1
    }

    # Create Staging Environment
    Write-Status "=== Creating Staging Environment ===" "INFO"
    $stagingParams = @{
        ResourceGroupName = $ResourceGroupName
        Location = $Location
        AppServiceName = "$BaseAppName-staging"
        SqlServerName = "$($BaseAppName.Replace('-', ''))serverstg"
        SqlDatabaseName = "Connect2US_Staging"
        SqlAdminUser = $SqlAdminUser
        SqlAdminPassword = $SqlAdminPassword
        SubscriptionId = $SubscriptionId
    }

    Write-Status "Running Create-AzureResources-PS.ps1 for Staging..." "INFO"
    & ".\Create-AzureResources-PS.ps1" @stagingParams

    if ($LASTEXITCODE -ne 0) {
        Write-Status "Staging environment creation failed" "ERROR"
        exit 1
    }

    Write-Status "=== Azure Environment Setup Complete ===" "SUCCESS"
    Write-Status "Production URL: https://$BaseAppName.azurewebsites.net" "SUCCESS"
    Write-Status "Staging URL: https://$BaseAppName-staging.azurewebsites.net" "SUCCESS"
    Write-Status "Resource Group: $ResourceGroupName" "SUCCESS"
    
    Write-Status "Next steps:" "INFO"
    Write-Status "1. Configure GitHub secrets with the publish profiles" "INFO"
    Write-Status "2. Update the connection strings in your Web.config if needed" "INFO"
    Write-Status "3. Trigger a deployment from GitHub Actions" "INFO"

} catch {
    Write-Status "Error setting up Azure environment: $($_.Exception.Message)" "ERROR"
    exit 1
}