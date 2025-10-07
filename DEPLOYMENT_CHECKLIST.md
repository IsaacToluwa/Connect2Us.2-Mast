# Azure Deployment Checklist for Connect2Us Application

## Pre-Deployment Checklist

### 1. Azure Resources Setup
- [ ] Create Azure SQL Database
- [ ] Create Azure App Service Plan (Standard S1 or higher)
- [ ] Create Azure App Service
- [ ] Configure Application Insights (optional but recommended)

### 2. Database Configuration
- [ ] Update connection string in `Web.Release.config`
- [ ] Test Entity Framework migrations locally
- [ ] Backup existing data if migrating from another database

### 3. Payment Gateway Setup
- [ ] Create Stripe production account
- [ ] Update Stripe keys in `Web.Release.config`
- [ ] Test payment flow in production environment

### 4. Security Configuration
- [ ] Enable HTTPS-only in App Service
- [ ] Configure custom domain and SSL certificate
- [ ] Set up authentication if required
- [ ] Configure CORS settings if needed

### 5. Application Settings
- [ ] Configure App Service Application Settings
- [ ] Set environment variables
- [ ] Configure connection strings

## Deployment Steps

### Step 1: Build Application
```bash
# Build in Release mode
msbuild Connect2Us.2.csproj /p:Configuration=Release
```

### Step 2: Publish to Azure
1. Right-click project in Visual Studio
2. Select "Publish"
3. Choose "Azure App Service"
4. Select your App Service
5. Click "Publish"

### Step 3: Database Migration
After deployment, run migrations:
```bash
# Using Package Manager Console
Update-Database -ConnectionString "YOUR_AZURE_CONNECTION_STRING"
```

### Step 4: Post-Deployment Verification
- [ ] Test all user roles (Admin, Bookstore, Customer, Delivery Driver)
- [ ] Verify payment processing with Stripe
- [ ] Test email notifications
- [ ] Check all CRUD operations
- [ ] Verify cart and checkout flow
- [ ] Test order management

## Monitoring & Maintenance

### Application Insights
- [ ] Set up custom telemetry
- [ ] Configure alerts for errors
- [ ] Monitor performance metrics

### Backup Strategy
- [ ] Configure automated database backups
- [ ] Set up geo-replication if needed
- [ ] Document recovery procedures

### Scaling Configuration
- [ ] Configure auto-scaling rules
- [ ] Set up load balancing if needed
- [ ] Monitor resource usage

## Troubleshooting Common Issues

### Database Connection Issues
- Check connection string format
- Verify firewall rules for Azure SQL
- Ensure proper authentication

### Payment Gateway Issues
- Verify Stripe webhook configuration
- Check API keys are correct
- Test in Stripe's test mode first

### Performance Issues
- Monitor database query performance
- Check for missing indexes
- Review application logs

## Support Contacts
- Azure Support: Through Azure Portal
- Stripe Support: support.stripe.com
- Application Developer: Your development team