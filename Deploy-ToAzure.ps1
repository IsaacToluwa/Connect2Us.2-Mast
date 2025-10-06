# Connect2Us Azure Deployment Script
# This script deploys the Connect2Us application to Azure App Service

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$AppServiceName,
    
    [Parameter(Mandatory=$true)]
    [string]$Location,
    
    [Parameter(Mandatory=$true)]
    [string]$SqlServerName,
    
    [Parameter(Mandatory=$true)]
    [string]$SqlDatabaseName,
    
    [Parameter(Mandatory=$true)]
    [string]$SqlAdminUser,
    
    [Parameter(Mandatory=$true)]
    [string]$SqlAdminPassword,
    
    [string]$SubscriptionId = "",
    
    [switch]$CreateNewResources = $false,
    
    [switch]$DeployDatabase = $true,
    
    [switch]$SkipBuild = $false
)

# Set error action preference
$ErrorActionPreference = "Stop"

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

# Function to check if Azure CLI is installed
function Test-AzureCLI {
    try {
        $azVersion = az --version 2>$null
        return $true
    }
    catch {
        return $false
    }
}

# Function to check if user is logged into Azure
function Test-AzureLogin {
    try {
        $account = az account show 2>$null | ConvertFrom-Json
        return ($null -ne $account)
    }
    catch {
        return $false
    }
}

# Function to create Azure resources
function New-AzureResources {
    Write-Status "Creating Azure resources..." "INFO"
    
    # Create Resource Group
    Write-Status "Creating Resource Group: $ResourceGroupName" "INFO"
    az group create --name $ResourceGroupName --location $Location
    
    # Create App Service Plan
    Write-Status "Creating App Service Plan..." "INFO"
    az appservice plan create --name "$AppServiceName-plan" --resource-group $ResourceGroupName --sku B1 --is-linux false
    
    # Create Web App
    Write-Status "Creating Web App: $AppServiceName" "INFO"
    az webapp create --name $AppServiceName --resource-group $ResourceGroupName --plan "$AppServiceName-plan" --runtime "aspnet:4.8"
    
    # Create SQL Server
    Write-Status "Creating SQL Server: $SqlServerName" "INFO"
    az sql server create --name $SqlServerName --resource-group $ResourceGroupName --location $Location --admin-user $SqlAdminUser --admin-password $SqlAdminPassword
    
    # Configure SQL Server firewall
    Write-Status "Configuring SQL Server firewall..." "INFO"
    az sql server firewall-rule create --resource-group $ResourceGroupName --server $SqlServerName --name AllowAzureServices --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0
    az sql server firewall-rule create --resource-group $ResourceGroupName --server $SqlServerName --name AllowAllWindowsAzureIps --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0
    
    # Create SQL Database
    Write-Status "Creating SQL Database: $SqlDatabaseName" "INFO"
    az sql db create --resource-group $ResourceGroupName --server $SqlServerName --name $SqlDatabaseName --service-objective S0
    
    # Configure app settings
    Write-Status "Configuring app settings..." "INFO"
    $connectionString = "Server=tcp:$SqlServerName.database.windows.net,1433;Initial Catalog=$SqlDatabaseName;Persist Security Info=False;User ID=$SqlAdminUser;Password=$SqlAdminPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    
    az webapp config appsettings set --name $AppServiceName --resource-group $ResourceGroupName --settings "DefaultConnection=$connectionString"
    
    Write-Status "Azure resources created successfully!" "SUCCESS"
}

# Function to build the application
function Invoke-Build {
    Write-Status "Building Connect2Us application..." "INFO"
    
    # Restore NuGet packages
    Write-Status "Restoring NuGet packages..." "INFO"
    nuget restore Connect2Us.2.sln
    
    # Build the solution
    Write-Status "Building solution..." "INFO"
    msbuild Connect2Us.2.sln /p:Configuration=Release /p:Platform="Any CPU" /p:DeployOnBuild=true /p:PublishProfile=FolderProfile
    
    if ($LASTEXITCODE -ne 0) {
        throw "Build failed with exit code $LASTEXITCODE"
    }
    
    Write-Status "Build completed successfully!" "SUCCESS"
}

# Function to deploy the application
function Invoke-Deploy {
    Write-Status "Deploying Connect2Us to Azure..." "INFO"
    
    # Create deployment package
    $publishFolder = "published"
    if (Test-Path $publishFolder) {
        Remove-Item $publishFolder -Recurse -Force
    }
    
    # Publish the application
    Write-Status "Publishing application..." "INFO"
    msbuild Connect2Us.2.csproj /p:Configuration=Release /p:Platform="Any CPU" /p:DeployOnBuild=true /p:PublishProfile=FolderProfile /p:PublishUrl=$publishFolder
    
    if ($LASTEXITCODE -ne 0) {
        throw "Publish failed with exit code $LASTEXITCODE"
    }
    
    # Deploy to Azure
    Write-Status "Deploying to Azure App Service..." "INFO"
    
    # Create ZIP deployment package
    $zipFile = "Connect2Us-Deployment.zip"
    if (Test-Path $zipFile) {
        Remove-Item $zipFile -Force
    }
    
    Compress-Archive -Path "$publishFolder\*" -DestinationPath $zipFile -Force
    
    # Deploy using ZIP deployment
    az webapp deployment source config-zip --resource-group $ResourceGroupName --name $AppServiceName --src $zipFile
    
    Write-Status "Deployment completed successfully!" "SUCCESS"
}

# Function to deploy database
function Invoke-DatabaseDeploy {
    if ($DeployDatabase) {
        Write-Status "Deploying database..." "INFO"
        
        # Build connection string
        $connectionString = "Server=tcp:$SqlServerName.database.windows.net,1433;Initial Catalog=$SqlDatabaseName;Persist Security Info=False;User ID=$SqlAdminUser;Password=$SqlAdminPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
        
        # Run database migrations
        Write-Status "Running Entity Framework migrations..." "INFO"
        
        # Update the connection string in Web.config temporarily
        $webConfigPath = "Web.config"
        $webConfigContent = Get-Content $webConfigPath -Raw
        $updatedContent = $webConfigContent -replace 'name="DefaultConnection" connectionString="[^"]*"', "name=\"DefaultConnection\" connectionString=\"$connectionString\""
        Set-Content -Path $webConfigPath -Value $updatedContent
        
        try {
            # Run migrations
            & "packages\EntityFramework.6.5.1\tools\net45\any\ef6.exe" database update --connection-string "$connectionString" --connection-provider "System.Data.SqlClient"
            
            Write-Status "Database deployment completed!" "SUCCESS"
        }
        finally {
            # Restore original Web.config
            Set-Content -Path $webConfigPath -Value $webConfigContent
        }
    }
}

# Function to verify deployment
function Test-Deployment {
    Write-Status "Verifying deployment..." "INFO"
    
    # Get the web app URL
    $webApp = az webapp show --name $AppServiceName --resource-group $ResourceGroupName | ConvertFrom-Json
    $appUrl = "https://$($webApp.defaultHostName)"
    
    Write-Status "Application URL: $appUrl" "INFO"
    
    # Test if the application is responding
    try {
        $response = Invoke-WebRequest -Uri $appUrl -TimeoutSec 30
        if ($response.StatusCode -eq 200) {
            Write-Status "Application is responding successfully!" "SUCCESS"
        } else {
            Write-Status "Application returned status code: $($response.StatusCode)" "WARNING"
        }
    }
    catch {
        Write-Status "Application test failed: $($_.Exception.Message)" "WARNING"
    }
    
    return $appUrl
}

# Main deployment process
try {
    Write-Status "Starting Connect2Us Azure Deployment..." "INFO"
    Write-Status "=========================================" "INFO"
    
    # Check prerequisites
    Write-Status "Checking prerequisites..." "INFO"
    
    if (-not (Test-AzureCLI)) {
        throw "Azure CLI is not installed. Please install Azure CLI from https://aka.ms/installazurecliwindows"
    }
    
    if (-not (Test-AzureLogin)) {
        Write-Status "Please login to Azure..." "INFO"
        az login
    }
    
    if ($SubscriptionId) {
        Write-Status "Setting subscription to $SubscriptionId" "INFO"
        az account set --subscription $SubscriptionId
    }
    
    # Create resources if requested
    if ($CreateNewResources) {
        New-AzureResources
    }
    
    # Build the application
    if (-not $SkipBuild) {
        Invoke-Build
    }
    
    # Deploy the application
    Invoke-Deploy
    
    # Deploy database
    Invoke-DatabaseDeploy
    
    # Verify deployment
    $appUrl = Test-Deployment
    
    Write-Status "=========================================" "INFO"
    Write-Status "Deployment completed successfully!" "SUCCESS"
    Write-Status "Application URL: $appUrl" "SUCCESS"
    Write-Status "=========================================" "INFO"
    
}
catch {
    Write-Status "Deployment failed: $($_.Exception.Message)" "ERROR"
    Write-Status "Error details: $($_.Exception)" "ERROR"
    exit 1
}
finally {
    # Cleanup deployment package
    if (Test-Path "Connect2Us-Deployment.zip") {
        Remove-Item "Connect2Us-Deployment.zip" -Force -ErrorAction SilentlyContinue
    }
}