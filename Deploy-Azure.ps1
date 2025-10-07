# Azure Deployment Script for Connect2Us.2
# This script creates a deployment package and provides deployment instructions

param(
    [string]$webAppName = "connect2us-app",
    [string]$resourceGroup = "connect2us-rg",
    [string]$deploymentPackagePath = "DeploymentPackage"
)

Write-Host "=== Connect2Us.2 Azure Deployment Script ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Build the project
Write-Host "Step 1: Building the project..." -ForegroundColor Yellow
$msbuildPath = "${env:ProgramFiles}\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe"
if (-not (Test-Path $msbuildPath)) {
    $msbuildPath = "${env:ProgramFiles}\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe"
}

if (Test-Path $msbuildPath) {
    & $msbuildPath Connect2Us.2.csproj /p:Configuration=Release /p:Platform="AnyCPU"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Build failed!"
        exit 1
    }
} else {
    Write-Warning "MSBuild not found. Make sure the project is built in Release mode."
}

# Step 2: Create deployment package
Write-Host "Step 2: Creating deployment package..." -ForegroundColor Yellow
if (Test-Path $deploymentPackagePath) {
    Remove-Item $deploymentPackagePath -Recurse -Force
}
New-Item -ItemType Directory -Path $deploymentPackagePath -Force | Out-Null

# Copy essential files
Copy-Item "Web.config" $deploymentPackagePath
Copy-Item "Global.asax" $deploymentPackagePath
Copy-Item "packages.config" $deploymentPackagePath
Copy-Item "bin" $deploymentPackagePath -Recurse
Copy-Item "Content" $deploymentPackagePath -Recurse
Copy-Item "Scripts" $deploymentPackagePath -Recurse
Copy-Item "Views" $deploymentPackagePath -Recurse
Copy-Item "App_Start" $deploymentPackagePath -Recurse
Copy-Item "Controllers" $deploymentPackagePath -Recurse
Copy-Item "Models" $deploymentPackagePath -Recurse
Copy-Item "Infrastructure" $deploymentPackagePath -Recurse
Copy-Item "Services" $deploymentPackagePath -Recurse
Copy-Item "ViewModels" $deploymentPackagePath -Recurse
Copy-Item "fonts" $deploymentPackagePath -Recurse -ErrorAction SilentlyContinue
Copy-Item "Images" $deploymentPackagePath -Recurse -ErrorAction SilentlyContinue

# Step 3: Create ZIP package
Write-Host "Step 3: Creating ZIP package..." -ForegroundColor Yellow
$zipPath = "Connect2Us.2-Deployment.zip"
if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

Compress-Archive -Path "$deploymentPackagePath\*" -DestinationPath $zipPath -Force

Write-Host ""
Write-Host "=== Deployment Package Created Successfully! ===" -ForegroundColor Green
Write-Host "Package location: $zipPath" -ForegroundColor Green
Write-Host ""
Write-Host "=== Next Steps for Azure Deployment ===" -ForegroundColor Cyan
Write-Host "1. Upload the ZIP file to your Azure Web App using one of these methods:" -ForegroundColor White
Write-Host "   - Azure Portal: Go to your Web App → Advanced Tools → Kudu → Debug console → Drag & drop files" -ForegroundColor Gray
Write-Host "   - Azure CLI: az webapp deployment source config-zip --resource-group $resourceGroup --name $webAppName --src $zipPath" -ForegroundColor Gray
Write-Host "   - FTP: Use the deployment credentials from Azure Portal" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Configure connection strings in Azure Portal:" -ForegroundColor White
Write-Host "   - Go to your Web App → Configuration → Connection strings" -ForegroundColor Gray
Write-Host "   - Add your Azure SQL Database connection string" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Set environment variables for Stripe keys:" -ForegroundColor White
Write-Host "   - Go to your Web App → Configuration → Application settings" -ForegroundColor Gray
Write-Host "   - Add: STRIPE_PUBLISHABLE_KEY and STRIPE_SECRET_KEY" -ForegroundColor Gray
Write-Host ""
Write-Host "Deployment package is ready!" -ForegroundColor Green