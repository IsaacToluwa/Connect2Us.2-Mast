# Manual Azure Deployment Setup Guide

This guide will help you manually prepare your Connect2Us project for Azure deployment.

## Step 1: Backup Your Current Configuration

1. Navigate to your project folder: `C:\Users\olatu\source\repos\Connect2Us.2-master`
2. Find the file `Web.config`
3. Right-click on it and select "Copy"
4. Right-click in the same folder and select "Paste"
5. Rename the copy to `Web.config.backup`

## Step 2: Update Connection Strings in Web.config

1. Open `Web.config` in a text editor (like Notepad or Visual Studio)
2. Find the connection strings section (around line 9-15)
3. **Replace the `DefaultConnection` string with your Azure SQL details:**

**Current (LocalDB):**
```xml
<add name="DefaultConnection" connectionString="Data Source=(localdb)\MSSQLLocalDB;Initial Catalog=Connect2US;Integrated Security=True;MultipleActiveResultSets=True;App=EntityFramework" providerName="System.Data.SqlClient" />
```

**New (Azure SQL):**
```xml
<add name="DefaultConnection" connectionString="Server=tcp:your-server.database.windows.net,1433;Database=Connect2US;User ID=your-username;Password=your-password;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30" providerName="System.Data.SqlClient" />
```

**Replace:**
- `your-server.database.windows.net` with your actual Azure SQL server name
- `your-username` with your Azure SQL username
- `your-password` with your Azure SQL password

## Step 3: Update Entity Framework Configuration

1. In the same `Web.config` file, find the `entityFramework` section (around line 70-80)
2. **Replace this section:**

**Current:**
```xml
<entityFramework>
  <defaultConnectionFactory type="System.Data.Entity.Infrastructure.LocalDbConnectionFactory, EntityFramework">
    <parameters>
      <parameter value="mssqllocaldb" />
    </parameters>
  </defaultConnectionFactory>
</entityFramework>
```

**New:**
```xml
<entityFramework>
  <defaultConnectionFactory type="System.Data.Entity.Infrastructure.SqlConnectionFactory, EntityFramework" />
</entityFramework>
```

## Step 4: Create Deployment Package

1. Create a new folder called `AzureDeployment` in your project directory
2. Copy these files to the `AzureDeployment` folder:
   - `Web.config` (your updated version)
   - `Global.asax`
   - `Connect2Us.2.csproj`
   - `packages.config`

3. Copy these folders to the `AzureDeployment` folder:
   - `Controllers`
   - `Models`
   - `Views`
   - `Content`
   - `Scripts`
   - `App_Start`
   - `App_Data`

## Step 5: Verify Your Changes

1. Open your updated `Web.config` file
2. Check that:
   - No references to `(localdb)\MSSQLLocalDB`
   - No references to `LocalDB`
   - No references to `AttachDbFilename`
   - Connection string points to Azure SQL server
   - Entity Framework uses `SqlConnectionFactory` instead of `LocalDbConnectionFactory`

## Step 6: Set Up Azure Resources

You'll need these Azure resources:

### Azure SQL Database
1. Go to [Azure Portal](https://portal.azure.com)
2. Create a new SQL Database
3. Server name: `connect2us-server` (or your choice)
4. Database name: `Connect2US`
5. Remember the server name, username, and password

### Azure App Service
1. In Azure Portal, create a new App Service
2. Choose your subscription and resource group
3. App name: `connect2us-app` (must be unique)
4. Runtime stack: `.NET Framework 4.8`

## Step 7: Set Up GitHub Secrets

1. Go to your GitHub repository
2. Go to Settings → Secrets and variables → Actions
3. Add these secrets:

```
AZURE_SUBSCRIPTION_ID=your-azure-subscription-id
AZURE_RESOURCE_GROUP=your-resource-group-name
AZURE_SQL_CONNECTION_STRING=Server=tcp:your-server.database.windows.net,1433;Database=Connect2US;User ID=your-username;Password=your-password;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30
STRIPE_PUBLISHABLE_KEY=your-stripe-publishable-key
STRIPE_SECRET_KEY=your-stripe-secret-key
```

## Step 8: Deploy to Azure

You can deploy using:
1. **GitHub Actions** (recommended) - see `AZURE_DEPLOYMENT_CHECKLIST.md`
2. **Visual Studio** - Right-click project → Publish → Azure
3. **Azure CLI** - Use `az webapp deployment source config-zip`

## Need Help?

If you need help with any of these steps:

1. **Check the Azure Portal** for resource creation
2. **Review the `AZURE_DEPLOYMENT_CHECKLIST.md`** for detailed steps
3. **Use Azure CLI** for automation:
   ```bash
   az login
   az account set --subscription "your-subscription-id"
   az group create --name "connect2us-rg" --location "East US"
   ```

## Demo Connection String

If you want to test with a demo connection string first:
```
Server=tcp:demo-server.database.windows.net,1433;Database=Connect2US;User ID=demouser;Password=DemoPassword123!;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30
```

**Remember to replace this with your actual Azure SQL details before production deployment!**