# Connect2Us Azure Deployment Guide for Student Account

## Prerequisites

### Azure Student Account Requirements
- **Azure for Students**: Provides $100 credit for 12 months
- **Academic Verification**: Requires valid student email (.edu, .ac.uk, etc.)
- **Free Services**: Access to Azure App Service, Azure SQL Database (free tier), Storage
- **Limitations**: Default $0 spending limit, no Marketplace offers

### What You'll Need
- Visual Studio 2019/2022 with Azure development workload
- Azure subscription (student account)
- Your current Connect2Us application

## Step-by-Step Deployment Process

### 1. Prepare Your Application for Azure

#### Update Connection Strings
Your `Web.Release.config` is already configured with Azure SQL Database connection string placeholder. You'll need to update it with your actual Azure SQL Database details after creation.

#### Update Stripe Keys (Optional)
Replace the placeholder Stripe keys in `Web.Release.config` with your production keys:
```xml
<add key="StripePublishableKey" value="pk_live_YOUR_ACTUAL_KEY"/>
<add key="StripeSecretKey" value="sk_live_YOUR_ACTUAL_KEY"/>
```

### 2. Create Azure Resources

#### Create Azure App Service Plan (Free Tier)
1. Go to [Azure Portal](https://portal.azure.com)
2. Click "Create a resource" → "Web App"
3. Choose your subscription and resource group (create new if needed)
4. **Web App Settings**:
   - Name: `connect2us-student-app` (must be unique)
   - Publish: Code
   - Runtime stack: .NET Framework 4.7.2
   - Operating System: Windows
   - Region: Choose closest to you
5. **App Service Plan**:
   - Create new plan
   - Name: `connect2us-student-plan`
   - Pricing tier: **F1 Free** (for student account)
6. Click "Review + Create" → "Create"

#### Create Azure SQL Database (Free Tier)
1. Go to "Create a resource" → "SQL Database"
2. **Database Settings**:
   - Database name: `Connect2UsDB`
   - Server: Create new server
     - Server name: `connect2us-student-server` (unique)
     - Server admin login: `sqladmin`
     - Password: Create strong password
     - Location: Same as your app service
3. **Compute + Storage**:
   - Choose **Free** tier (if available for students)
   - Otherwise choose **Basic** (lowest cost)
4. Click "Review + Create" → "Create"

#### Create Azure Storage Account (Optional)
1. Go to "Create a resource" → "Storage Account"
2. **Basics**:
   - Name: `connect2usstudent` (lowercase, unique)
   - Performance: Standard
   - Redundancy: LRS (Locally-redundant storage)
3. Choose **Free** tier if available

### 3. Configure Application Settings

#### Update Connection String in Azure
1. Go to your App Service → "Configuration" → "Connection strings"
2. Click "+ New connection string"
3. **Settings**:
   - Name: `DefaultConnection`
   - Value: `Server=tcp:connect2us-student-server.database.windows.net,1433;Initial Catalog=Connect2UsDB;Persist Security Info=False;User ID=sqladmin;Password=YOUR_PASSWORD;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;`
   - Type: SQLAzure
4. Click "OK" → "Save"

#### Update Web.Release.config
Replace the connection string placeholder in your `Web.Release.config` with the actual connection string from Azure.

### 4. Deploy Your Application

#### Option A: Deploy from Visual Studio (Recommended)
1. **Right-click your project** → "Publish"
2. Choose **Azure** → "Azure App Service (Windows)"
3. **Sign in** to your Azure account
4. Select your App Service (`connect2us-student-app`)
5. Click "Finish" → "Publish"
6. Wait for deployment to complete

#### Option B: Deploy from GitHub (CI/CD)
1. Push your code to GitHub repository
2. In Azure Portal, go to your App Service
3. Go to "Deployment Center"
4. Choose "GitHub" as source
5. Configure repository and branch
6. Azure will automatically deploy on push

### 5. Database Migration

#### Enable Code First Migrations
1. In Visual Studio, open **Package Manager Console**
2. Run these commands:
```powershell
Enable-Migrations -ContextTypeName Connect2Us.Models.ApplicationDbContext
Add-Migration "InitialCreate" -IgnoreChanges
Update-Database -ConnectionString "YOUR_AZURE_CONNECTION_STRING"
```

#### Alternative: Use SQL Script
1. Generate SQL script from your local database
2. In Azure Portal, go to your SQL Database
3. Open **Query Editor** and run the script

### 6. Test Your Deployment

#### Basic Functionality Tests
1. Navigate to your app URL: `https://connect2us-student-app.azurewebsites.net`
2. Test user registration and login
3. Test wallet functionality (the fix we implemented)
4. Test payment processing (if Stripe is configured)
5. Test all user roles (Customer, Bookstore, Delivery Driver)

#### Performance Testing
1. Test page load times
2. Check database query performance
3. Monitor Azure metrics in portal

### 7. Monitor and Maintain

#### Set Up Monitoring
1. In Azure Portal, go to your App Service
2. Enable **Application Insights** (free tier)
3. Set up alerts for:
   - HTTP 5xx errors
   - Response time > 5 seconds
   - Database connection failures

#### Regular Maintenance
1. Monitor usage and costs
2. Keep within free tier limits
3. Update dependencies regularly
4. Backup your database weekly

## Student Account Best Practices

### Cost Management
- **Set spending limits** in Azure Cost Management
- **Monitor usage** weekly to avoid charges
- **Use free tiers** for all services
- **Delete unused resources** to avoid charges

### Resource Optimization
- **App Service**: Use F1 Free tier (1GB storage, 1GB memory)
- **SQL Database**: Use Free tier (32MB storage, 5 DTUs)
- **Storage**: Use LRS redundancy (cheapest)

### Security Recommendations
- **Enable HTTPS only** in App Service settings
- **Use managed identity** for database access
- **Rotate connection strings** regularly
- **Enable firewall rules** for SQL Database

## Troubleshooting Common Issues

### Database Connection Issues
- Verify connection string format
- Check SQL Database firewall rules
- Ensure SQL authentication is enabled

### Deployment Failures
- Check build output for errors
- Verify .NET Framework version compatibility
- Ensure all NuGet packages are restored

### Performance Issues
- Monitor Application Insights for bottlenecks
- Check database query performance
- Consider caching strategies

## Next Steps

After successful deployment:
1. **Set up custom domain** (optional)
2. **Configure SSL certificate** (free with Azure)
3. **Implement caching** for better performance
4. **Add more monitoring** and logging
5. **Consider scaling** if traffic increases

## Support Resources

- [Azure for Students](https://azure.microsoft.com/en-us/free/students/)
- [Azure App Service Documentation](https://docs.microsoft.com/en-us/azure/app-service/)
- [Azure SQL Database Documentation](https://docs.microsoft.com/en-us/azure/azure-sql/)
- [Visual Studio Publish to Azure](https://docs.microsoft.com/en-us/visualstudio/deployment/quickstart-deploy-to-azure?view=vs-2022)

---

**Note**: This guide is specifically tailored for Azure student accounts with free tier limitations. Always monitor your usage to stay within the free tier limits and avoid unexpected charges.