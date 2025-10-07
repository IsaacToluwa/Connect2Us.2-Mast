# 🚀 Azure Deployment Checklist for Connect2Us

## ✅ Pre-Deployment Status
Your project diagnosis shows:
- ✅ **Project Structure**: All folders present (Controllers, Models, Views, etc.)
- ✅ **Configuration Files**: Web.config and packages.config found
- ✅ **GitHub Actions**: Workflow file exists
- ✅ **Database Setup**: Migrations and MigrationRunner present
- ⚠️ **Connection Issues**: Still using LocalDB, needs Azure SQL

## 🎯 Deployment Strategy

### Option 1: Quick Start (Recommended)
Use the automated deployment scripts I created:

1. **Prepare for Azure** (Run this first):
   ```powershell
   .\Deploy-Azure-Ready.ps1 -AzureSqlServer "your-server.database.windows.net" -AzureSqlDatabase "Connect2US" -AzureSqlUser "sqladmin" -AzureSqlPassword "your-password"
   ```

2. **Set up GitHub Secrets**:
   ```powershell
   .\Setup-GitHub-Secrets.ps1
   ```

### Option 2: Manual Deployment
Follow the step-by-step checklist below:

---

## 📋 Step-by-Step Deployment Checklist

### Phase 1: Azure Resources Setup
- [ ] **Create Azure Resources**
  - [ ] Resource Group (e.g., `connect2us-rg`)
  - [ ] App Service Plan (Windows, .NET Framework)
  - [ ] Web App (ASP.NET 4.7.2)
  - [ ] SQL Database (Azure SQL)
  - [ ] SQL Server with firewall rules

- [ ] **Configure SQL Database**
  - [ ] Create database schema
  - [ ] Set up firewall rules (allow Azure services)
  - [ ] Create SQL user with appropriate permissions
  - [ ] Test connection from local machine

### Phase 2: Application Configuration
- [ ] **Update Web.config**
  - [ ] Replace LocalDB connection with Azure SQL
  - [ ] Update Entity Framework configuration
  - [ ] Configure SMTP settings for production
  - [ ] Update Stripe keys for production

- [ ] **Environment-Specific Settings**
  - [ ] Create Web.Release.config transformations
  - [ ] Set up application settings in Azure
  - [ ] Configure connection strings in Azure

### Phase 3: GitHub Integration (Different Accounts)
Since your GitHub and Azure accounts are different:

- [ ] **Set up GitHub Secrets** (Manual process required)
  - [ ] `AZURE_SUBSCRIPTION_ID` - Your Azure subscription ID
  - [ ] `AZURE_RESOURCE_GROUP` - Your resource group name
  - [ ] `AZURE_SQL_CONNECTION_STRING` - Azure SQL connection string
  - [ ] `STRIPE_PUBLISHABLE_KEY` - Production Stripe key
  - [ ] `STRIPE_SECRET_KEY` - Production Stripe secret

- [ ] **Service Principal Setup** (Optional but recommended)
  - [ ] Create Azure Service Principal
  - [ ] Grant necessary permissions
  - [ ] Add client ID and secret to GitHub secrets

### Phase 4: Database Migration
- [ ] **Prepare Migration Strategy**
  - [ ] Test migrations locally with Azure SQL
  - [ ] Create migration script for production
  - [ ] Set up database initialization

- [ ] **Run Migrations**
  - [ ] Execute migrations against Azure SQL
  - [ ] Verify database schema
  - [ ] Seed initial data if needed

### Phase 5: Deployment & Testing
- [ ] **Deploy Application**
  - [ ] Trigger GitHub Actions deployment
  - [ ] Monitor deployment logs
  - [ ] Verify successful deployment

- [ ] **Post-Deployment Testing**
  - [ ] Test application functionality
  - [ ] Verify database connectivity
  - [ ] Test payment processing (Stripe)
  - [ ] Check email functionality
  - [ ] Validate user authentication

### Phase 6: Monitoring & Maintenance
- [ ] **Set up Monitoring**
  - [ ] Configure Application Insights
  - [ ] Set up alerts for errors
  - [ ] Monitor performance metrics

- [ ] **Security Review**
  - [ ] Verify HTTPS is enabled
  - [ ] Check firewall rules
  - [ ] Review access permissions
  - [ ] Update dependencies

---

## 🔧 Common Issues & Solutions

### Issue: "Localhost references found"
**Solution**: Run the deployment preparation script or manually update Web.config

### Issue: "GitHub Actions workflow missing"
**Solution**: Ensure `.github/workflows/main_connect2us.yml` exists

### Issue: "Azure publish profiles missing"
**Solution**: Create publish profiles or use GitHub Actions deployment

### Issue: "Database connection failed"
**Solution**: Check SQL firewall rules and connection string format

---

## 📁 Files Created for You

1. **`diagnosis.bat`** - Quick project health check
2. **`Deploy-Azure-Ready.ps1`** - Automates Web.config updates
3. **`Setup-GitHub-Secrets.ps1`** - Guides GitHub secrets setup
4. **`AZURE_DEPLOYMENT_CHECKLIST.md`** - This comprehensive guide

---

## 🚀 Next Steps

1. **Run the diagnosis**: `.\diagnosis.bat`
2. **Prepare for Azure**: `.\Deploy-Azure-Ready.ps1` with your Azure SQL details
3. **Set up GitHub secrets**: Follow the guide in `.\Setup-GitHub-Secrets.ps1`
4. **Deploy**: Use GitHub Actions or manual deployment

## 💡 Pro Tips

- **Test locally first**: Always test your Azure SQL connection locally before deployment
- **Use staging**: Consider creating a staging environment first
- **Monitor logs**: Check Azure logs and GitHub Actions for deployment issues
- **Backup**: Keep backups of your original configuration files
- **Security**: Never commit secrets to your repository

---

**Need help?** Check the Azure portal for deployment logs, or run the diagnosis script to identify issues.