# Azure Deployment Configuration

## App Service Plan Configuration
- **Tier**: Standard S1 (minimum for production)
- **Instance Size**: Small (1 core, 1.75 GB RAM)
- **Operating System**: Windows
- **Runtime Stack**: .NET Framework 4.7.2

## Application Settings (Configure in Azure Portal)
1. **Connection Strings**:
   - Name: `DefaultConnection`
   - Value: Your Azure SQL Database connection string
   - Type: SQLAzure

2. **App Settings**:
   - `ASPNETCORE_ENVIRONMENT`: Production
   - `WEBSITE_RUN_FROM_PACKAGE`: 1
   - `StripePublishableKey`: Your production Stripe publishable key
   - `StripeSecretKey`: Your production Stripe secret key
   - `StripeEnabled`: true

## Custom Domains & SSL
- Configure custom domain in Azure App Service
- Upload SSL certificate for HTTPS
- Enable "HTTPS Only" in App Service settings

## Scaling Configuration
- **Auto-scaling**: Enable based on CPU percentage (70% threshold)
- **Minimum instances**: 1
- **Maximum instances**: 3

## Monitoring & Logging
- Enable Application Insights
- Configure log streaming
- Set up alerts for HTTP 5xx errors

## Security Settings
- Enable CORS if needed for API access
- Configure authentication/authorization if required
- Set up IP restrictions if needed