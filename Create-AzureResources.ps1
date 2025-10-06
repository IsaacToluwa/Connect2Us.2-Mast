# Connect2Us Azure Resource Creation Script
# This script creates the necessary Azure resources for the Connect2Us application

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$Location,
    
    [Parameter(Mandatory=$true)]
    [string]$AppServiceName,
    
    [Parameter(Mandatory=$true)]
    [string]$SqlServerName,
    
    [Parameter(Mandatory=$true)]
    [string]$SqlDatabaseName,
    
    [Parameter(Mandatory=$true)]
    [string]$SqlAdminUser,
    
    [Parameter(Mandatory=$true)]
    [string]$SqlAdminPassword,
    
    [string]$SubscriptionId = "",
    
    [string]$AppServicePlanSku = "B1",
    
    [string]$DatabaseServiceObjective = "S0"
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

# Function to validate Azure resource names
function Test-ResourceName {
    param([string]$Name, [string]$Type)
    
    switch ($Type) {
        "ResourceGroup" {
            # Resource Group names: 1-90 characters, alphanumeric, underscore, parentheses, hyphen, period
            return ($Name -match '^[a-zA-Z0-9_\-\.\(\)]{1,90}$')
        }
        "AppService" {
            # App Service names: 2-60 characters, alphanumeric and hyphen
            return ($Name -match '^[a-zA-Z0-9\-]{2,60}$')
        }
        "SqlServer" {
            # SQL Server names: 1-63 characters, lowercase alphanumeric and hyphen
            return ($Name -match '^[a-z0-9\-]{1,63}$')
        }
        "SqlDatabase" {
            # SQL Database names: 1-128 characters, cannot contain <>*:%?&/\ or control characters
            return ($Name -match '^[^<>\*:%\?&\/\\\x00-\x1F\x7F]{1,128}$')
        }
    }
    return $false
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

# Function to check resource availability
function Test-ResourceAvailability {
    param([string]$Name, [string]$Type)
    
    Write-Status "Checking availability of $Name ($Type)..." "INFO"
    
    try {
        switch ($Type) {
            "AppService" {
                $result = az webapp list --query "[?name=='$Name']" -o json | ConvertFrom-Json
                return ($result.Count -eq 0)
            }
            "SqlServer" {
                $result = az sql server list --query "[?name=='$Name']" -o json | ConvertFrom-Json
                return ($result.Count -eq 0)
            }
        }
    }
    catch {
        Write-Status "Error checking resource availability: $($_.Exception.Message)" "WARNING"
        return $false
    }
}

# Function to create Resource Group
function New-ResourceGroup {
    Write-Status "Creating Resource Group: $ResourceGroupName" "INFO"
    
    try {
        $existingRg = az group show --name $ResourceGroupName 2>$null | ConvertFrom-Json
        if ($existingRg) {
            Write-Status "Resource Group $ResourceGroupName already exists." "WARNING"
            return $existingRg
        }
        
        $rg = az group create --name $ResourceGroupName --location $Location | ConvertFrom-Json
        Write-Status "Resource Group created successfully!" "SUCCESS"
        return $rg
    }
    catch {
        throw "Failed to create Resource Group: $($_.Exception.Message)"
    }
}

# Function to create App Service Plan
function New-AppServicePlan {
    Write-Status "Creating App Service Plan: $AppServiceName-plan" "INFO"
    
    try {
        $existingPlan = az appservice plan list --resource-group $ResourceGroupName --query "[?name=='$AppServiceName-plan']" -o json | ConvertFrom-Json
        if ($existingPlan) {
            Write-Status "App Service Plan $AppServiceName-plan already exists." "WARNING"
            return $existingPlan[0]
        }
        
        $plan = az appservice plan create `
            --name "$AppServiceName-plan" `
            --resource-group $ResourceGroupName `
            --location $Location `
            --sku $AppServicePlanSku `
            --is-linux false | ConvertFrom-Json
        
        Write-Status "App Service Plan created successfully!" "SUCCESS"
        return $plan
    }
    catch {
        throw "Failed to create App Service Plan: $($_.Exception.Message)"
    }
}

# Function to create Web App
function New-WebApp {
    Write-Status "Creating Web App: $AppServiceName" "INFO"
    
    try {
        $existingApp = az webapp list --query "[?name=='$AppServiceName']" -o json | ConvertFrom-Json
        if ($existingApp) {
            Write-Status "Web App $AppServiceName already exists." "WARNING"
            return $existingApp[0]
        }
        
        $app = az webapp create `
            --name $AppServiceName `
            --resource-group $ResourceGroupName `
            --plan "$AppServiceName-plan" `
            --runtime "aspnet:4.8" | ConvertFrom-Json
        
        Write-Status "Web App created successfully!" "SUCCESS"
        return $app
    }
    catch {
        throw "Failed to create Web App: $($_.Exception.Message)"
    }
}

# Function to create SQL Server
function New-SqlServer {
    Write-Status "Creating SQL Server: $SqlServerName" "INFO"
    
    try {
        $existingServer = az sql server list --query "[?name=='$SqlServerName']" -o json | ConvertFrom-Json
        if ($existingServer) {
            Write-Status "SQL Server $SqlServerName already exists." "WARNING"
            return $existingServer[0]
        }
        
        $server = az sql server create `
            --name $SqlServerName `
            --resource-group $ResourceGroupName `
            --location $Location `
            --admin-user $SqlAdminUser `
            --admin-password $SqlAdminPassword | ConvertFrom-Json
        
        Write-Status "SQL Server created successfully!" "SUCCESS"
        return $server
    }
    catch {
        throw "Failed to create SQL Server: $($_.Exception.Message)"
    }
}

# Function to configure SQL Server firewall
function Set-SqlFirewallRules {
    Write-Status "Configuring SQL Server firewall rules..." "INFO"
    
    try {
        # Allow Azure services
        az sql server firewall-rule create `
            --resource-group $ResourceGroupName `
            --server $SqlServerName `
            --name AllowAzureServices `
            --start-ip-address 0.0.0.0 `
            --end-ip-address 0.0.0.0
        
        # Allow all Windows Azure IPs (for App Service)
        az sql server firewall-rule create `
            --resource-group $ResourceGroupName `
            --server $SqlServerName `
            --name AllowAllWindowsAzureIps `
            --start-ip-address 0.0.0.0 `
            --end-ip-address 0.0.0.0
        
        Write-Status "SQL Server firewall rules configured successfully!" "SUCCESS"
    }
    catch {
        throw "Failed to configure SQL Server firewall: $($_.Exception.Message)"
    }
}

# Function to create SQL Database
function New-SqlDatabase {
    Write-Status "Creating SQL Database: $SqlDatabaseName" "INFO"
    
    try {
        $existingDb = az sql db list --resource-group $ResourceGroupName --server $SqlServerName --query "[?name=='$SqlDatabaseName']" -o json | ConvertFrom-Json
        if ($existingDb) {
            Write-Status "SQL Database $SqlDatabaseName already exists." "WARNING"
            return $existingDb[0]
        }
        
        $db = az sql db create `
            --resource-group $ResourceGroupName `
            --server $SqlServerName `
            --name $SqlDatabaseName `
            --service-objective $DatabaseServiceObjective | ConvertFrom-Json
        
        Write-Status "SQL Database created successfully!" "SUCCESS"
        return $db
    }
    catch {
        throw "Failed to create SQL Database: $($_.Exception.Message)"
    }
}

# Function to configure Web App settings
function Set-WebAppSettings {
    Write-Status "Configuring Web App settings..." "INFO"
    
    try {
        # Build connection string
        $connectionString = "Server=tcp:$SqlServerName.database.windows.net,1433;Initial Catalog=$SqlDatabaseName;Persist Security Info=False;User ID=$SqlAdminUser;Password=$SqlAdminPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
        
        # Set connection string
        az webapp config connection-string set `
            --name $AppServiceName `
            --resource-group $ResourceGroupName `
            --connection-string-type SQLAzure `
            --settings "DefaultConnection=$connectionString"
        
        # Set app settings
        az webapp config appsettings set `
            --name $AppServiceName `
            --resource-group $ResourceGroupName `
            --settings "ASPNETCORE_ENVIRONMENT=Production" "WEBSITE_RUN_FROM_PACKAGE=1"
        
        # Configure general settings
        az webapp config set `
            --name $AppServiceName `
            --resource-group $ResourceGroupName `
            --always-on true `
            --http20-enabled true
        
        Write-Status "Web App settings configured successfully!" "SUCCESS"
    }
    catch {
        throw "Failed to configure Web App settings: $($_.Exception.Message)"
    }
}

# Function to display resource information
function Show-ResourceInfo {
    Write-Status "=========================================" "INFO"
    Write-Status "Azure Resources Created/Configured" "INFO"
    Write-Status "=========================================" "INFO"
    
    # Resource Group
    $rg = az group show --name $ResourceGroupName | ConvertFrom-Json
    Write-Status "Resource Group: $($rg.name)" "INFO"
    Write-Status "  Location: $($rg.location)" "INFO"
    Write-Status "  ID: $($rg.id)" "INFO"
    
    # App Service Plan
    $plan = az appservice plan show --name "$AppServiceName-plan" --resource-group $ResourceGroupName | ConvertFrom-Json
    Write-Status "App Service Plan: $($plan.name)" "INFO"
    Write-Status "  SKU: $($plan.sku.name)" "INFO"
    Write-Status "  Worker Size: $($plan.workerSize)" "INFO"
    Write-Status "  Number of Workers: $($plan.numberOfWorkers)" "INFO"
    
    # Web App
    $app = az webapp show --name $AppServiceName --resource-group $ResourceGroupName | ConvertFrom-Json
    Write-Status "Web App: $($app.name)" "INFO"
    Write-Status "  URL: https://$($app.defaultHostName)" "INFO"
    Write-Status "  State: $($app.state)" "INFO"
    Write-Status "  Runtime: $($app.siteConfig.netFrameworkVersion)" "INFO"
    
    # SQL Server
    $server = az sql server show --name $SqlServerName --resource-group $ResourceGroupName | ConvertFrom-Json
    Write-Status "SQL Server: $($server.name)" "INFO"
    Write-Status "  Fully Qualified Domain Name: $($server.fullyQualifiedDomainName)" "INFO"
    Write-Status "  Version: $($server.version)" "INFO"
    
    # SQL Database
    $db = az sql db show --name $SqlDatabaseName --server $SqlServerName --resource-group $ResourceGroupName | ConvertFrom-Json
    Write-Status "SQL Database: $($db.name)" "INFO"
    Write-Status "  Status: $($db.status)" "INFO"
    Write-Status "  Service Level Objective: $($db.serviceLevelObjective)" "INFO"
    Write-Status "  Max Size: $($db.maxSizeBytes / 1GB) GB" "INFO"
    
    Write-Status "=========================================" "INFO"
    Write-Status "Connection String:" "INFO"
    $connectionString = "Server=tcp:$SqlServerName.database.windows.net,1433;Initial Catalog=$SqlDatabaseName;Persist Security Info=False;User ID=$SqlAdminUser;Password=$SqlAdminPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    Write-Status $connectionString "INFO"
    Write-Status "=========================================" "INFO"
}

# Main execution
try {
    Write-Status "Starting Connect2Us Azure Resource Creation..." "INFO"
    Write-Status "=========================================" "INFO"
    
    # Validate prerequisites
    Write-Status "Validating prerequisites..." "INFO"
    
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
    
    # Validate resource names
    Write-Status "Validating resource names..." "INFO"
    
    if (-not (Test-ResourceName -Name $ResourceGroupName -Type "ResourceGroup")) {
        throw "Invalid Resource Group name: $ResourceGroupName"
    }
    
    if (-not (Test-ResourceName -Name $AppServiceName -Type "AppService")) {
        throw "Invalid App Service name: $AppServiceName"
    }
    
    if (-not (Test-ResourceName -Name $SqlServerName -Type "SqlServer")) {
        throw "Invalid SQL Server name: $SqlServerName (must be lowercase)"
    }
    
    if (-not (Test-ResourceName -Name $SqlDatabaseName -Type "SqlDatabase")) {
        throw "Invalid SQL Database name: $SqlDatabaseName"
    }
    
    # Check resource availability
    if (-not (Test-ResourceAvailability -Name $AppServiceName -Type "AppService")) {
        Write-Status "App Service name $AppServiceName is not available." "WARNING"
    }
    
    if (-not (Test-ResourceAvailability -Name $SqlServerName -Type "SqlServer")) {
        Write-Status "SQL Server name $SqlServerName is not available." "WARNING"
    }
    
    # Create resources
    $resourceGroup = New-ResourceGroup
    $appServicePlan = New-AppServicePlan
    $webApp = New-WebApp
    $sqlServer = New-SqlServer
    Set-SqlFirewallRules
    $sqlDatabase = New-SqlDatabase
    Set-WebAppSettings
    
    # Display resource information
    Show-ResourceInfo
    
    Write-Status "Azure resource creation completed successfully!" "SUCCESS"
    Write-Status "=========================================" "SUCCESS"
    
}
catch {
    Write-Status "Resource creation failed: $($_.Exception.Message)" "ERROR"
    Write-Status "Error details: $($_.Exception)" "ERROR"
    exit 1
}