# Azure OIDC Authentication Setup Commands
# Run these commands one by one in PowerShell

Write-Host "Azure OIDC Authentication Setup Commands" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green

Write-Host "`nStep 1: Check Azure Login" -ForegroundColor Cyan
Write-Host "Command: az account show" -ForegroundColor Yellow

Write-Host "`nStep 2: Create App Registration (if needed)" -ForegroundColor Cyan
Write-Host "Command: az ad app create --display-name 'Connect2Us-GitHub-Actions'" -ForegroundColor Yellow

Write-Host "`nStep 3: Get App ID and Object ID" -ForegroundColor Cyan
Write-Host "Command: `$appId = az ad app list --display-name 'Connect2Us-GitHub-Actions' --query '[0].appId' -o tsv" -ForegroundColor Yellow
Write-Host "Command: `$appObjectId = az ad app list --display-name 'Connect2Us-GitHub-Actions' --query '[0].id' -o tsv" -ForegroundColor Yellow

Write-Host "`nStep 4: Create Federated Credential" -ForegroundColor Cyan
Write-Host "Command: az ad app federated-credential create --id `$appObjectId --name 'Connect2Us-GitHub-FIC' --issuer 'https://token.actions.githubusercontent.com' --subject 'repo:IsaacToluwa/Connect2Us.2-Mast:environment:Production' --description 'GitHub Actions OIDC authentication for Connect2Us' --audiences 'api://AzureADTokenExchange'" -ForegroundColor Yellow

Write-Host "`nStep 5: Create Service Principal (if needed)" -ForegroundColor Cyan
Write-Host "Command: az ad sp create --id `$appId" -ForegroundColor Yellow

Write-Host "`nStep 6: Get Web App ID" -ForegroundColor Cyan
Write-Host "Command: `$webAppId = az webapp list --query '[?name==''Connect2US''].id' -o tsv" -ForegroundColor Yellow

Write-Host "`nStep 7: Assign Role" -ForegroundColor Cyan
Write-Host "Command: az role assignment create --assignee `$appId --role 'Website Contributor' --scope `$webAppId" -ForegroundColor Yellow

Write-Host "`nStep 8: Get Required IDs" -ForegroundColor Cyan
Write-Host "Command: `$tenantId = az account show --query 'tenantId' -o tsv" -ForegroundColor Yellow
Write-Host "Command: `$subscriptionId = az account show --query 'id' -o tsv" -ForegroundColor Yellow

Write-Host "`n✅ MANUAL SETUP COMPLETE!" -ForegroundColor Green
Write-Host "Update these GitHub secrets:" -ForegroundColor Cyan
Write-Host "AZUREAPPSERVICE_CLIENTID_188E64413313450BA987CB17A2AB8FDB = (use `$appId)" -ForegroundColor Yellow
Write-Host "AZUREAPPSERVICE_TENANTID_C2DAC1E1B3D84CC99FED2841F7FB4839 = (use `$tenantId)" -ForegroundColor Yellow
Write-Host "AZUREAPPSERVICE_SUBSCRIPTIONID_5E03C99C396E4E34A4B56AC7A1487628 = (use `$subscriptionId)" -ForegroundColor Yellow