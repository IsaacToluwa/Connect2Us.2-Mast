# Azure Domain Settings Configuration for Connect2Us

## Domain Configuration

### Custom Domain Setup
# Primary Domain: connect2us.co.za
# Alternative: www.connect2us.co.za
# Azure App Service Default: connect2us-app.azurewebsites.net

## DNS Configuration
# Add these DNS records to your domain registrar:

### A Record (Root Domain)
# Type: A
# Name: @ (or connect2us.co.za)
# Value: [Your Azure App Service IP Address]
# TTL: 3600

### CNAME Record (WWW)
# Type: CNAME
# Name: www
# Value: connect2us-app.azurewebsites.net
# TTL: 3600

### TXT Record (Domain Verification)
# Type: TXT
# Name: @
# Value: [Azure-provided verification token]
# TTL: 3600

## Azure App Service Custom Domain Settings

### 1. Domain Verification
# In Azure Portal > App Services > Your App > Custom Domains
# Add custom domain: connect2us.co.za
# Add custom domain: www.connect2us.co.za

### 2. SSL Certificate Configuration
# Recommended: Use Azure Managed Certificates (Free)
# Or upload your own SSL certificate

### 3. HTTPS Redirection
# Enable "HTTPS Only" in App Service settings
# Configure automatic HTTP to HTTPS redirection

## Application Settings for Production Domain

### Web.Release.config Updates
# The following settings should be added to Web.Release.config:

<add key="WebsiteDomain" value="https://connect2us.co.za" xdt:Transform="Insert"/>
<add key="WebsiteUrl" value="https://connect2us.co.za" xdt:Transform="Insert"/>
<add key="EnableSSL" value="true" xdt:Transform="Insert"/>

### Email Configuration Updates
# Update email settings for production domain:

<add key="SMTPServer" value="smtp.your-provider.com" xdt:Transform="Insert"/>
<add key="SMTPPort" value="587" xdt:Transform="Insert"/>
<add key="SMTPUsername" value="noreply@connect2us.co.za" xdt:Transform="Insert"/>
<add key="SMTPPassword" value="your-email-password" xdt:Transform="Insert"/>
<add key="SMTPFromEmail" value="noreply@connect2us.co.za" xdt:Transform="Insert"/>
<add key="SMTPFromName" value="Connect2Us" xdt:Transform="Insert"/>

## Stripe Webhook Configuration

### Production Webhook URL
# https://connect2us.co.za/stripe/webhook

### Webhook Events to Subscribe:
# - payment_intent.succeeded
# - payment_intent.payment_failed
# - checkout.session.completed
# - invoice.payment_succeeded
# - invoice.payment_failed

## Security Headers for Production

### Additional Headers to Add in Web.Release.config:
<add name="Strict-Transport-Security" value="max-age=31536000; includeSubDomains" xdt:Transform="Insert"/>
<add name="Content-Security-Policy" value="default-src 'self'; script-src 'self' 'unsafe-inline' https://js.stripe.com; frame-src https://js.stripe.com https://hooks.stripe.com; connect-src 'self' https://api.stripe.com;" xdt:Transform="Insert"/>
<add name="Referrer-Policy" value="strict-origin-when-cross-origin" xdt:Transform="Insert"/>

## Search Engine Optimization (SEO)

### Robots.txt
# Create robots.txt file in root directory:
User-agent: *
Allow: /
Disallow: /admin/
Disallow: /account/
Sitemap: https://connect2us.co.za/sitemap.xml

### Sitemap.xml
# Generate and submit sitemap to search engines

## Performance Optimization

### CDN Configuration
# Consider using Azure CDN for static content:
# - CSS files
# - JavaScript files
# - Product images
# - User-uploaded content

### Caching Headers
# Configure output caching for:
# - Product catalog pages
# - Static content
# - API responses

## Monitoring and Analytics

### Application Insights
# Configure custom events for:
# - User registrations
# - Order completions
# - Payment failures
# - Search queries

### Google Analytics
# Add tracking code for production domain

## Backup and Disaster Recovery

### Database Backups
# Enable automated backups in Azure SQL Database
# Configure geo-replication for disaster recovery

### Application Backups
# Enable App Service backups
# Configure backup schedule and retention

## Support and Maintenance

### Contact Information
# Technical Support: support@connect2us.co.za
# Customer Service: help@connect2us.co.za
# Domain Registrar: [Your registrar contact]
# Hosting Provider: Microsoft Azure

### Maintenance Windows
# Schedule regular maintenance:
# - Database optimization: Weekly
# - Application updates: Monthly
# - Security updates: As needed
# - Feature deployments: Bi-weekly

## Cost Optimization

### Azure Cost Management
# Monitor usage and costs in Azure Cost Management
# Set up budget alerts
# Consider Azure Reservations for predictable workloads

### Resource Optimization
# Right-size App Service Plan based on usage
# Use Azure Advisor recommendations
# Implement auto-scaling policies