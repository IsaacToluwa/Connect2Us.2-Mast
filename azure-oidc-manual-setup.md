# Azure OIDC Authentication Manual Setup Guide

## Problem Summary
Your GitHub Actions workflow is failing with error `AADSTS700213` because the federated identity credential is missing or incorrectly configured.

## Prerequisites
- Azure Portal access (https://portal.azure.com)
- GitHub repository access
- Azure subscription with appropriate permissions

## Step-by-Step Manual Setup

### Step 1: Create Azure App Registration
1. Go to Azure Portal → Azure Active Directory → App registrations
2. Click "New registration"
3. Name: `Connect2Us-GitHub-Actions`
4. Supported account types: "Accounts in this organizational directory only"
5. Click "Register"
6. Note the **Application (client) ID** and **Directory (tenant) ID**

### Step 2: Create Federated Credential
1. In the app registration, go to "Certificates & secrets"
2. Click "Federated credentials" tab
3. Click "Add credential"
4. Federated credential scenario: "GitHub Actions deploying Azure resources"
5. Fill in the details:
   - **Organization**: IsaacToluwa
   - **Repository**: Connect2Us.2-Mast
   - **Entity type**: Environment
   - **GitHub Environment name**: Production
   - **Name**: Connect2Us-GitHub-FIC
6. Click "Add"

### Step 3: Create Service Principal (if not exists)
1. Go to Azure Active Directory → Enterprise applications
2. Search for "Connect2Us-GitHub-Actions"
3. If not found, the service principal will be created automatically when you assign roles

### Step 4: Assign Role to Web App
1. Go to your Connect2US web app in Azure Portal
2. Go to "Access control (IAM)"
3. Click "Add" → "Add role assignment"
4. Role: "Website Contributor"
5. Assign access to: "User, group, or service principal"
6. Search for: "Connect2Us-GitHub-Actions"
7. Select it and click "Review + assign"

### Step 5: Update GitHub Secrets
Go to your GitHub repository → Settings → Secrets and variables → Actions

Update these secrets with the values from Step 1:
- **AZUREAPPSERVICE_CLIENTID_188E64413313450BA987CB17A2AB8FDB** = Application (client) ID
- **AZUREAPPSERVICE_TENANTID_C2DAC1E1B3D84CC99FED2841F7FB4839** = Directory (tenant) ID
- **AZUREAPPSERVICE_SUBSCRIPTIONID_5E03C99C396E4E34A4B56AC7A1487628** = Your Azure subscription ID

### Step 6: Verify Configuration
1. Go to Azure Active Directory → App registrations → Connect2Us-GitHub-Actions
2. Check "Federated credentials" - should show your GitHub connection
3. Go to your web app → Access control (IAM) → Role assignments
4. Verify "Connect2Us-GitHub-Actions" has "Website Contributor" role

### Step 7: Test the Workflow
1. Go to GitHub repository → Actions
2. Trigger a new workflow run
3. The Azure login should now succeed

## Troubleshooting

If you still get errors:

1. **Check the federated credential subject**: It should exactly match:
   ```
   repo:IsaacToluwa/Connect2Us.2-Mast:environment:Production
   ```

2. **Verify GitHub Environment**: Make sure you have a "Production" environment configured in your GitHub repository settings

3. **Check role assignment**: Ensure the service principal has the correct role on the web app

4. **Verify secrets**: Double-check all GitHub secrets have the correct values

## Need Help?

If you encounter issues:
- Check Azure AD sign-in logs for detailed error information
- Verify the federated credential was created successfully
- Ensure your Azure subscription has the necessary permissions
- Check that your GitHub repository has the required environments configured

After completing these steps, your GitHub Actions workflow should be able to authenticate to Azure using OIDC and deploy your application successfully.