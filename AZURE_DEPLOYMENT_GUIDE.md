# Connect2Us Azure Deployment Guide

This guide provides comprehensive instructions for deploying the Connect2Us application to Microsoft Azure.

## Prerequisites

Before you begin, ensure you have the following:

### Required Software
- **Azure CLI** (Latest version): [Download and install](https://aka.ms/installazurecliwindows)
- **PowerShell** (5.1 or later)
- **.NET Framework 4.8** or later
- **Visual Studio 2019/2022** (recommended) or **MSBuild**
- **Git** for version control

### Azure Requirements
- Active Azure subscription
- Appropriate permissions to create and manage resources
- Azure Resource Group (will be created if it doesn't exist)

### Local Requirements
- Clone of the Connect2Us repository
- NuGet package manager
- SQL Server Management Studio (SSMS) - optional, for database management

## Quick Start

### 1. Azure Login
```powershell
az login
```

### 2. Create Azure Resources
Use the provided PowerShell script to create all necessary Azure resources:

```powershell
.\Create-AzureResources.ps1 `
  -ResourceGroupName "Connect2Us-RG" `
  -Location "eastus" `
  -AppServiceName "connect2us-app" `
  -SqlServerName "connect2usserver" `
  -SqlDatabaseName "Connect2US" `
  -SqlAdminUser "Connect_Admin" `
  -SqlAdminPassword "YourSecurePassword123!"
```

### 3. Deploy Application
Deploy the application using the main deployment script:

```powershell
.\Deploy-ToAzure.ps1 `
  -ResourceGroupName "Connect2Us-RG" `
  -AppServiceName "connect2us-app" `
  -Location "eastus" `
  -SqlServerName "connect2usserver" `
  -SqlDatabaseName "Connect2US" `
  -SqlAdminUser "Connect_Admin" `
  -SqlAdminPassword "YourSecurePassword123!"
```

## Detailed Deployment Steps

### Step 1: Prepare Your Environment

1. **Install Azure CLI**
   ```powershell
   # Download and install Azure CLI
   Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile AzureCLI.msi
   Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'
   ```

2. **Verify Installation**
   ```powershell
   az --version
   az login
   ```

### Step 2: Resource Creation

The `Create-AzureResources.ps1` script creates the following Azure resources:

- **Resource Group**: Container for all resources
- **App Service Plan**: Hosting plan for the web application
- **Web App**: Azure App Service for hosting the application
- **SQL Server**: Azure SQL Database server
- **SQL Database**: Database for the application
- **Firewall Rules**: Security rules for database access

#### Resource Naming Conventions
- **Resource Group**: `Connect2Us-RG` or your preferred name
- **App Service**: Must be globally unique (e.g., `connect2us-app-yourname`)
- **SQL Server**: Must be globally unique (e.g., `connect2usserver-yourname`)
- **SQL Database**: `Connect2US` (or your preferred name)

### Step 3: Application Deployment

The `Deploy-ToAzure.ps1` script performs:

1. **Build Process**
   - Restores NuGet packages
   - Builds the solution in Release mode
   - Creates deployment package

2. **Database Deployment**
   - Applies Entity Framework migrations
   - Updates database schema

3. **Application Deployment**
   - Creates ZIP deployment package
   - Deploys to Azure App Service
   - Configures application settings

4. **Verification**
   - Tests application availability
   - Validates deployment success

### Step 4: Database Migration

Use the `Migrate-Database.ps1` script for database operations:

```powershell
# Update database with migrations
.\Migrate-Database.ps1 `
  -ConnectionString "Server=tcp:connect2usserver.database.windows.net,1433;Initial Catalog=Connect2US;Persist Security Info=False;User ID=Connect_Admin;Password=YourPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

# Generate migration script
.\Migrate-Database.ps1 `
  -ConnectionString "your-connection-string" `
  -ScriptMigration `
  -OutputScriptPath "migration-script.sql"
```

## Configuration

### Web.config Settings
The application uses the following connection strings:

```xml
<connectionStrings>
  <add name="DefaultConnection" 
       connectionString="Server=tcp:connect2usserver.database.windows.net,1433;Initial Catalog=Connect2US;Persist Security Info=False;User ID=Connect_Admin;Password=YourPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
       providerName="System.Data.SqlClient" />
</connectionStrings>
```

### Azure App Service Settings
The deployment script automatically configures:

- **Connection Strings**: Database connection
- **App Settings**: Environment variables
- **General Settings**: Always On, HTTP/2, etc.

## GitHub Actions Deployment

The repository includes a GitHub Actions workflow (`.github/workflows/main_connect2us.yml`) for automated deployment:

### Features
- **Automated Builds**: Triggered on push to main/master/develop branches
- **Multi-Environment**: Support for staging and production environments
- **Database Migration**: Automated database updates
- **Security Scanning**: Integrated security checks
- **Performance Testing**: Automated performance validation

### Setup
1. Create GitHub secrets:
   - `AZURE_CREDENTIALS`: Azure service principal credentials
   - `AZURE_SQL_CONNECTION_STRING`: Production database connection string
   - `AZURE_SQL_CONNECTION_STRING_STAGING`: Staging database connection string

2. Configure workflow variables in the YAML file

3. Push to trigger deployment

## Security Considerations

### Connection Strings
- Never commit connection strings with passwords to source control
- Use Azure Key Vault for production secrets
- Rotate passwords regularly

### Network Security
- Configure firewall rules to restrict access
- Use Private Endpoints for production environments
- Enable Azure AD authentication where possible

### Application Security
- Enable HTTPS only
- Configure security headers
- Regular security scanning

## Troubleshooting

### Common Issues

1. **Azure CLI Login Issues**
   ```powershell
   az login --use-device-code
   ```

2. **Resource Name Conflicts**
   - App Service and SQL Server names must be globally unique
   - Add suffixes or use different names

3. **Database Connection Issues**
   - Verify firewall rules are configured
   - Check connection string format
   - Test connectivity using SSMS

4. **Build Failures**
   - Ensure all NuGet packages are restored
   - Check MSBuild version compatibility
   - Verify project references

### Logs and Diagnostics

1. **Azure App Service Logs**
   ```powershell
   az webapp log tail --name <app-name> --resource-group <rg-name>
   ```

2. **Application Logs**
   - Enable application logging in Azure Portal
   - Check Kudu console for detailed logs

3. **Database Logs**
   - Use Azure SQL Database audit logs
   - Check query performance insights

## Monitoring and Maintenance

### Application Insights
Configure Application Insights for:
- Performance monitoring
- Error tracking
- Usage analytics

### Backup Strategy
- Enable automated SQL Database backups
- Configure long-term retention policies
- Test restore procedures regularly

### Scaling
- Configure auto-scaling rules
- Monitor performance metrics
- Adjust App Service plan as needed

## Cost Optimization

### Resource Sizing
- Start with smaller SKUs (B1, S0)
- Monitor usage and scale up as needed
- Use Azure Cost Management for tracking

### Development vs Production
- Use different resource groups
- Consider Azure Dev/Test pricing
- Implement proper resource tagging

## Support and Resources

### Azure Documentation
- [Azure App Service Documentation](https://docs.microsoft.com/azure/app-service/)
- [Azure SQL Database Documentation](https://docs.microsoft.com/azure/azure-sql/)
- [Azure CLI Reference](https://docs.microsoft.com/cli/azure/)

### PowerShell Help
```powershell
Get-Help .\Deploy-ToAzure.ps1 -Full
Get-Help .\Create-AzureResources.ps1 -Full
Get-Help .\Migrate-Database.ps1 -Full
```

### Getting Help
- Check Azure Service Health
- Review deployment logs
- Contact Azure Support if needed

## Next Steps

After successful deployment:

1. **Configure Custom Domain** (optional)
2. **Set up SSL Certificate** (recommended for production)
3. **Configure Application Insights**
4. **Set up monitoring and alerts**
5. **Implement backup strategies**
6. **Configure CI/CD pipeline**

---

For questions or issues, please refer to the troubleshooting section or create an issue in the repository.