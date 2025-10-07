# Connect2Us Deployment Configuration

## Overview
This document outlines the complete deployment configuration for the Connect2Us ASP.NET MVC application to Azure Web App using GitHub Actions.

## 🚀 Deployment Pipeline

### GitHub Actions Workflow
The deployment pipeline is configured in `.github/workflows/main_connect2us.yml` and includes:

1. **Build Job**: Compiles the application, restores NuGet packages, and creates deployment package
2. **Deploy Job**: Deploys to Azure Web App with proper verification steps

### Key Features
- **Automated Builds**: Triggered on pushes to main branch or manual dispatch
- **NuGet Caching**: Improves build performance
- **Comprehensive Packaging**: Includes all necessary files for ASP.NET MVC deployment
- **Azure Integration**: Uses Azure service principal for secure deployment
- **Verification Steps**: Pre and post-deployment checks

## 📁 Project Structure

### Essential Files
```
Connect2Us.2/
├── .github/workflows/main_connect2us.yml    # GitHub Actions workflow
├── Properties/PublishProfiles/
│   └── FileSystem.pubxml                   # MSBuild publish profile
├── Web.config                              # Base configuration
├── Web.Release.config                      # Production transformations
├── Global.asax                             # Application entry point
├── packages.config                         # NuGet packages
└── DEPLOYMENT.md                          # This file
```

### Build Configuration
- **Target Framework**: .NET Framework 4.7.2
- **Platform**: Any CPU
- **Configuration**: Release
- **Output Path**: `bin\`

## 🔧 Configuration Files

### 1. GitHub Actions Workflow (`main_connect2us.yml`)
- **Build Environment**: windows-latest
- **MSBuild Setup**: microsoft/setup-msbuild@v2
- **NuGet Setup**: NuGet/setup-nuget@v1.0.5
- **Package Creation**: Manual packaging for reliability
- **Azure Deployment**: azure/webapps-deploy@v3

### 2. Publish Profile (`FileSystem.pubxml`)
- **Method**: FileSystem
- **Configuration**: Release
- **Platform**: Any CPU
- **Precompilation**: Enabled
- **Debug Symbols**: Included

### 3. Web.config Transformations (`Web.Release.config`)
- **Production Settings**: Debug disabled, custom errors enabled
- **Security Headers**: X-Frame-Options, X-Content-Type-Options, etc.
- **HTTPS Redirect**: Automatic HTTP to HTTPS redirection
- **Connection Strings**: Azure SQL Database configuration
- **SMTP Settings**: SendGrid integration ready

## 🔄 Deployment Process

### Build Phase
1. **Checkout Code**: Gets latest source code
2. **Setup Tools**: MSBuild and NuGet
3. **Restore Packages**: Downloads and caches NuGet packages
4. **Build Application**: Compiles in Release mode
5. **Publish Application**: Uses FileSystem profile
6. **Create Package**: Manually packages all required files
7. **Upload Artifact**: Stores package for deployment

### Deploy Phase
1. **Download Artifact**: Retrieves build package
2. **Verify Package**: Checks essential files
3. **Azure Login**: Authenticates with service principal
4. **Deploy Application**: Pushes to Azure Web App
5. **Verify Deployment**: Confirms successful deployment

## 📦 Deployment Package Contents

The deployment package includes:
- **Application Binaries**: All DLL and PDB files
- **Configuration**: Web.config with production transformations
- **Web Content**: Views, Content, Scripts, fonts directories
- **Application Files**: Global.asax, favicon.ico
- **Content Files**: Static assets and resources

## 🔐 Security Configuration

### Azure Service Principal
The workflow uses these GitHub secrets:
- `AZUREAPPSERVICE_CLIENTID_188E64413313450BA987CB17A2AB8FDB`
- `AZUREAPPSERVICE_TENANTID_C2DAC1E1B3D84CC99FED2841F7FB4839`
- `AZUREAPPSERVICE_SUBSCRIPTIONID_5E03C99C396E4E34A4B56AC7A1487628`

### Production Security Features
- **HTTPS Enforcement**: Automatic HTTP to HTTPS redirect
- **Security Headers**: X-Frame-Options, X-XSS-Protection, etc.
- **Custom Errors**: User-friendly error pages
- **Cookie Security**: HttpOnly and Secure flags
- **Request Filtering**: Blocks dangerous file extensions

## 🛠️ Required Secrets

Configure these secrets in your GitHub repository settings:

```yaml
# Azure Service Principal (already configured)
AZUREAPPSERVICE_CLIENTID_188E64413313450BA987CB17A2AB8FDB
AZUREAPPSERVICE_TENANTID_C2DAC1E1B3D84CC99FED2841F7FB4839
AZUREAPPSERVICE_SUBSCRIPTIONID_5E03C99C396E4E34A4B56AC7A1487628

# Additional recommended secrets
STRIPE_SECRET_KEY: Your Stripe production secret key
SENDGRID_API_KEY: Your SendGrid API key for email
AZURE_SQL_CONNECTION_STRING: Azure SQL Database connection string
```

## 📋 Pre-Deployment Checklist

- [ ] Azure Web App created and configured
- [ ] Azure SQL Database set up
- [ ] Service principal configured with proper permissions
- [ ] GitHub secrets configured
- [ ] Production Stripe keys ready
- [ ] SendGrid account configured
- [ ] Custom domain configured (optional)
- [ ] SSL certificate installed (if using custom domain)

## 🔍 Post-Deployment Verification

After deployment, verify:
1. **Application Health**: Check if the site loads
2. **Database Connection**: Verify database connectivity
3. **Functionality**: Test key features (login, checkout, etc.)
4. **Performance**: Monitor response times
5. **Security**: Verify HTTPS and security headers
6. **Error Handling**: Test error pages work correctly

## 🚨 Troubleshooting

### Common Issues

1. **Build Failures**
   - Check NuGet package restore
   - Verify MSBuild version compatibility
   - Review build logs for specific errors

2. **Deployment Failures**
   - Verify Azure service principal permissions
   - Check Azure Web App configuration
   - Review deployment logs

3. **Runtime Issues**
   - Verify Web.config transformations applied
   - Check database connection string
   - Review Azure application logs

### Debug Steps
1. Check GitHub Actions build logs
2. Review Azure Web App diagnostic logs
3. Verify file deployment in Kudu console
4. Test database connectivity
5. Check application insights (if configured)

## 📞 Support

For deployment issues:
1. Check GitHub Actions logs for specific error messages
2. Review Azure Web App diagnostic logs
3. Verify all configuration files are properly set up
4. Ensure Azure resources are properly configured

## 🔄 Updates and Maintenance

### Regular Updates
- Monitor GitHub Actions for build failures
- Keep NuGet packages updated
- Review and update security configurations
- Monitor Azure resource usage and performance

### Configuration Updates
- Update `Web.Release.config` for new production settings
- Modify publish profile for deployment changes
- Update workflow for new build requirements
- Review and update security configurations

---

**Last Updated**: December 2024
**Application**: Connect2Us ASP.NET MVC
**Deployment Target**: Azure Web App
**CI/CD**: GitHub Actions