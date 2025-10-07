# Connect2Us Azure Resource Creation Script (PowerShell Version)
# This script creates the necessary Azure resources for the Connect2Us application using Azure PowerShell modules

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

# Function to check if user is logged into Azure
function Test-AzureLogin {
    try {
        $context = Get-AzContext
        return ($null -ne $context)
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
                $result = Get-AzWebApp -Name $Name -ErrorAction SilentlyContinue
                return ($null -eq $result)
            }
            "SqlServer" {
                $result = Get-AzSqlServer -ServerName $Name -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
                return ($null -eq $result)
            }
        }
    }
    catch {
        Write-Status "Error checking resource availability: $($_.Exception.Message)" "WARNING"
        return $false
    }
}

# Main script execution
try {
    Write-Status "Starting Azure resource creation for Connect2Us" "INFO"
    Write-Status "Parameters:" "INFO"
    Write-Status "  Resource Group: $ResourceGroupName" "INFO"
    Write-Status "  Location: $Location" "INFO"
    Write-Status "  App Service: $AppServiceName" "INFO"
    Write-Status "  SQL Server: $SqlServerName" "INFO"
    Write-Status "  SQL Database: $SqlDatabaseName" "INFO"

    # Validate resource names
    Write-Status "Validating resource names..." "INFO"
    
    if (-not (Test-ResourceName -Name $ResourceGroupName -Type "ResourceGroup")) {
        throw "Invalid Resource Group name: $ResourceGroupName"
    }
    
    if (-not (Test-ResourceName -Name $AppServiceName -Type "AppService")) {
        throw "Invalid App Service name: $AppServiceName"
    }
    
    if (-not (Test-ResourceName -Name $SqlServerName -Type "SqlServer")) {
        throw "Invalid SQL Server name: $SqlServerName"
    }
    
    if (-not (Test-ResourceName -Name $SqlDatabaseName -Type "SqlDatabase")) {
        throw "Invalid SQL Database name: $SqlDatabaseName"
    }

    # Check resource availability
    Write-Status "Checking resource availability..." "INFO"
    
    if (-not (Test-ResourceAvailability -Name $AppServiceName -Type "AppService")) {
        Write-Status "App Service name $AppServiceName is not available." "WARNING"
    }
    
    if (-not (Test-ResourceAvailability -Name $SqlServerName -Type "SqlServer")) {
        Write-Status "SQL Server name $SqlServerName is not available." "WARNING"
    }

    # Check if user is logged in
    if (-not (Test-AzureLogin)) {
        Write-Status "Please login to Azure using Connect-AzAccount and run this script again." "ERROR"
        throw "Azure login required"
    }

    # Set subscription if provided
    if ($SubscriptionId) {
        Set-AzContext -SubscriptionId $SubscriptionId
        Write-Status "Using subscription: $SubscriptionId" "INFO"
    }

    # Create Resource Group
    Write-Status "Creating Resource Group: $ResourceGroupName" "INFO"
    $resourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $resourceGroup) {
        $resourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Location
        Write-Status "Resource Group created successfully!" "SUCCESS"
    } else {
        Write-Status "Resource Group already exists." "WARNING"
    }

    # Create App Service Plan
    Write-Status "Creating App Service Plan: $AppServiceName-plan" "INFO"
    $appServicePlan = Get-AzAppServicePlan -ResourceGroupName $ResourceGroupName -Name "$AppServiceName-plan" -ErrorAction SilentlyContinue
    if (-not $appServicePlan) {
        $appServicePlan = New-AzAppServicePlan -ResourceGroupName $ResourceGroupName -Name "$AppServiceName-plan" -Location $Location -Tier $AppServicePlanSku -WorkerSize Small -Linux
        Write-Status "App Service Plan created successfully!" "SUCCESS"
    } else {
        Write-Status "App Service Plan already exists." "WARNING"
    }

    # Create Web App
    Write-Status "Creating Web App: $AppServiceName" "INFO"
    $webApp = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppServiceName -ErrorAction SilentlyContinue
    if (-not $webApp) {
        $webApp = New-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppServiceName -Location $Location -AppServicePlan $appServicePlan.Id
        Write-Status "Web App created successfully!" "SUCCESS"
        Write-Status "Web App URL: https://$($webApp.DefaultHostName)" "SUCCESS"
    } else {
        Write-Status "Web App already exists." "WARNING"
        Write-Status "Web App URL: https://$($webApp.DefaultHostName)" "INFO"
    }

    # Create SQL Server
    Write-Status "Creating SQL Server: $SqlServerName" "INFO"
    $sqlServer = Get-AzSqlServer -ResourceGroupName $ResourceGroupName -ServerName $SqlServerName -ErrorAction SilentlyContinue
    if (-not $sqlServer) {
        $securePassword = ConvertTo-SecureString $SqlAdminPassword -AsPlainText -Force
        $sqlServer = New-AzSqlServer -ResourceGroupName $ResourceGroupName -ServerName $SqlServerName -Location $Location -SqlAdministratorCredentials (New-Object System.Management.Automation.PSCredential ($SqlAdminUser, $securePassword))
        Write-Status "SQL Server created successfully!" "SUCCESS"
        Write-Status "SQL Server FQDN: $($sqlServer.FullyQualifiedDomainName)" "SUCCESS"
    } else {
        Write-Status "SQL Server already exists." "WARNING"
        Write-Status "SQL Server FQDN: $($sqlServer.FullyQualifiedDomainName)" "INFO"
    }

    # Create SQL Database
    Write-Status "Creating SQL Database: $SqlDatabaseName" "INFO"
    $sqlDatabase = Get-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $SqlServerName -DatabaseName $SqlDatabaseName -ErrorAction SilentlyContinue
    if (-not $sqlDatabase) {
        $sqlDatabase = New-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $SqlServerName -DatabaseName $SqlDatabaseName -RequestedServiceObjectiveName $DatabaseServiceObjective
        Write-Status "SQL Database created successfully!" "SUCCESS"
    } else {
        Write-Status "SQL Database already exists." "WARNING"
    }

    # Configure SQL Server firewall rule for Azure services
    Write-Status "Configuring SQL Server firewall for Azure services..." "INFO"
    $firewallRule = Get-AzSqlServerFirewallRule -ResourceGroupName $ResourceGroupName -ServerName $SqlServerName -FirewallRuleName "AllowAzureServices" -ErrorAction SilentlyContinue
    if (-not $firewallRule) {
        $firewallRule = New-AzSqlServerFirewallRule -ResourceGroupName $ResourceGroupName -ServerName $SqlServerName -FirewallRuleName "AllowAzureServices" -StartIpAddress "0.0.0.0" -EndIpAddress "0.0.0.0"
        Write-Status "SQL Server firewall rule created successfully!" "SUCCESS"
    } else {
        Write-Status "SQL Server firewall rule already exists." "WARNING"
    }

    # Configure Web App connection string
    Write-Status "Configuring Web App connection string..." "INFO"
    $connectionString = "Server=tcp:$($sqlServer.FullyQualifiedDomainName),1433;Initial Catalog=$SqlDatabaseName;Persist Security Info=False;User ID=$SqlAdminUser;Password=$SqlAdminPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    Set-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppServiceName -ConnectionStrings @{ DefaultConnection = @{ Value = $connectionString; Type = "SQLAzure" } }
    Write-Status "Web App connection string configured successfully!" "SUCCESS"

    # Configure Web App app settings
    Write-Status "Configuring Web App app settings..." "INFO"
    $appSettings = @{
        "WEBSITE_NODE_DEFAULT_VERSION" = "~18"
        "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
        "ASPNETCORE_ENVIRONMENT" = "Production"
    }
    Set-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppServiceName -AppSettings $appSettings
    Write-Status "Web App app settings configured successfully!" "SUCCESS"

    Write-Status "Azure resource creation completed successfully!" "SUCCESS"
    Write-Status "Production URL: https://$($webApp.DefaultHostName)" "SUCCESS"
    Write-Status "Database Connection String: $connectionString" "INFO"

} catch {
    Write-Status "Error creating Azure resources: $($_.Exception.Message)" "ERROR"
    Write-Status "Stack Trace: $($_.ScriptStackTrace)" "ERROR"
    exit 1
}