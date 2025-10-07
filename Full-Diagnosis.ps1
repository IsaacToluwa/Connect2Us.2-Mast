# Full Project Diagnosis Script
# This script performs a comprehensive analysis of the Connect2Us project
# without requiring Azure authentication

Write-Host "=== CONNECT2US PROJECT FULL DIAGNOSIS ===" -ForegroundColor Cyan
Write-Host "Analyzing project structure and configuration..." -ForegroundColor Gray
Write-Host ""

# 1. Project Structure Analysis
Write-Host "1. PROJECT STRUCTURE ANALYSIS" -ForegroundColor Yellow
Write-Host "----------------------------------------"

$requiredFolders = @("Controllers", "Models", "Views", "App_Data", "App_Start", "Content", "Scripts")
foreach ($folder in $requiredFolders) {
    if (Test-Path $folder) {
        $fileCount = (Get-ChildItem $folder -File -Recurse).Count
        Write-Host "✓ $folder found ($fileCount files)" -ForegroundColor Green
    } else {
        Write-Host "✗ $folder missing" -ForegroundColor Red
    }
}

Write-Host ""

# 2. Configuration Files Analysis
Write-Host "2. CONFIGURATION FILES ANALYSIS" -ForegroundColor Yellow
Write-Host "----------------------------------------"

# Check Web.config
if (Test-Path "Web.config") {
    Write-Host "✓ Web.config found" -ForegroundColor Green
    try {
        [xml]$webConfig = Get-Content "Web.config"
        
        # Check connection strings
        $connStrings = $webConfig.configuration.connectionStrings.add
        if ($connStrings) {
            Write-Host "  - Connection strings found:" -ForegroundColor Gray
            foreach ($conn in $connStrings) {
                Write-Host "    → $($conn.name)" -ForegroundColor Gray
            }
        }
        
        # Check app settings
        $appSettings = $webConfig.configuration.appSettings.add
        if ($appSettings) {
            Write-Host "  - App settings found: $($appSettings.Count)" -ForegroundColor Gray
        }
    } catch {
        Write-Host "✗ Error parsing Web.config: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "✗ Web.config missing" -ForegroundColor Red
}

# Check packages.config
if (Test-Path "packages.config") {
    Write-Host "✓ packages.config found" -ForegroundColor Green
    try {
        [xml]$packages = Get-Content "packages.config"
        $packageCount = $packages.packages.package.Count
        Write-Host "  - NuGet packages: $packageCount" -ForegroundColor Gray
        
        $efPackage = $packages.packages.package | Where-Object { $_.id -like "*EntityFramework*" }
        if ($efPackage) {
            Write-Host "  ✓ Entity Framework found: $($efPackage.version)" -ForegroundColor Green
        }
    } catch {
        Write-Host "✗ Error parsing packages.config: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "⚠ packages.config not found" -ForegroundColor Yellow
}

Write-Host ""

# 3. Build Configuration Analysis
Write-Host "3. BUILD CONFIGURATION ANALYSIS" -ForegroundColor Yellow
Write-Host "----------------------------------------"

# Check project file
$projFile = Get-ChildItem -Filter "*.csproj" | Select-Object -First 1
if ($projFile) {
    Write-Host "✓ Project file found: $($projFile.Name)" -ForegroundColor Green
    try {
        [xml]$proj = Get-Content $projFile.FullName
        
        # Check target framework
        $targetFramework = $proj.Project.PropertyGroup.TargetFramework
        if ($targetFramework) {
            Write-Host "  - Target Framework: $targetFramework" -ForegroundColor Gray
        } else {
            $targetFramework = $proj.Project.PropertyGroup.TargetFrameworkVersion
            if ($targetFramework) {
                Write-Host "  - Target Framework Version: $targetFramework" -ForegroundColor Gray
            }
        }
        
        # Check for Entity Framework
        $efRef = $proj.Project.ItemGroup.PackageReference | Where-Object { $_.Include -like "*EntityFramework*" }
        if ($efRef) {
            Write-Host "  ✓ Entity Framework reference found" -ForegroundColor Green
        }
    } catch {
        Write-Host "✗ Error parsing project file: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "✗ No .csproj file found" -ForegroundColor Red
}

Write-Host ""

# 4. GitHub Actions Workflow Analysis
Write-Host "4. GITHUB ACTIONS WORKFLOW ANALYSIS" -ForegroundColor Yellow
Write-Host "----------------------------------------"

$workflowPath = ".github\workflows\main_connect2us.yml"
if (Test-Path $workflowPath) {
    Write-Host "✓ GitHub Actions workflow found" -ForegroundColor Green
    try {
        $workflowContent = Get-Content $workflowPath -Raw
        
        if ($workflowContent -match "azure/webapps-deploy") {
            Write-Host "  ✓ Azure deployment step found" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ Azure deployment step not found" -ForegroundColor Yellow
        }
        
        if ($workflowContent -match "msbuild|dotnet build") {
            Write-Host "  ✓ Build step found" -ForegroundColor Green
        }
        
        if ($workflowContent -match "\$\{\{ secrets\.") {
            Write-Host "  ✓ GitHub secrets usage detected" -ForegroundColor Green
        }
    } catch {
        Write-Host "✗ Error reading workflow: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "✗ GitHub Actions workflow not found" -ForegroundColor Red
}

Write-Host ""

# 5. Azure Configuration Analysis
Write-Host "5. AZURE CONFIGURATION ANALYSIS" -ForegroundColor Yellow
Write-Host "----------------------------------------"

# Check publish profiles
$publishProfilesPath = "Properties\PublishProfiles"
if (Test-Path $publishProfilesPath) {
    $publishProfiles = Get-ChildItem $publishProfilesPath -Filter "*.pubxml"
    if ($publishProfiles) {
        Write-Host "✓ Publish profiles found: $($publishProfiles.Count)" -ForegroundColor Green
        foreach ($profile in $publishProfiles) {
            Write-Host "  - $($profile.Name)" -ForegroundColor Gray
        }
    } else {
        Write-Host "⚠ No publish profiles found" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠ Publish profiles directory not found" -ForegroundColor Yellow
}

# Check Azure scripts
$azureScripts = @("Create-AzureResources.ps1", "Deploy-ToAzure.ps1", "Create-AzureResources-PS.ps1")
foreach ($script in $azureScripts) {
    if (Test-Path $script) {
        Write-Host "✓ $script found" -ForegroundColor Green
    } else {
        Write-Host "⚠ $script not found" -ForegroundColor Yellow
    }
}

Write-Host ""

# 6. Database Migration Analysis
Write-Host "6. DATABASE MIGRATION ANALYSIS" -ForegroundColor Yellow
Write-Host "----------------------------------------"

if (Test-Path "Migrations") {
    Write-Host "✓ Migrations folder found" -ForegroundColor Green
    $migrationFiles = Get-ChildItem "Migrations" -Filter "*.cs"
    Write-Host "  - Migration files: $($migrationFiles.Count)" -ForegroundColor Gray
    
    if (Test-Path "Migrations\Configuration.cs") {
        Write-Host "  ✓ Migration configuration found" -ForegroundColor Green
    }
} else {
    Write-Host "⚠ Migrations folder not found" -ForegroundColor Yellow
}

if (Test-Path "MigrationRunner") {
    Write-Host "✓ MigrationRunner project found" -ForegroundColor Green
} else {
    Write-Host "⚠ MigrationRunner not found" -ForegroundColor Yellow
}

Write-Host ""

# 7. Application Structure Analysis
Write-Host "7. APPLICATION STRUCTURE ANALYSIS" -ForegroundColor Yellow
Write-Host "----------------------------------------"

# Controllers
if (Test-Path "Controllers") {
    $controllers = Get-ChildItem "Controllers" -Filter "*.cs"
    Write-Host "✓ Controllers: $($controllers.Count)" -ForegroundColor Green
    foreach ($controller in $controllers) {
        $name = $controller.Name.Replace("Controller.cs", "")
        Write-Host "  - $name" -ForegroundColor Gray
    }
}

# Models
if (Test-Path "Models") {
    $models = Get-ChildItem "Models" -Filter "*.cs"
    Write-Host "✓ Models: $($models.Count)" -ForegroundColor Green
    
    # Check for key models
    $keyModels = @("Product", "Order", "Customer", "Cart", "Payment")
    foreach ($model in $keyModels) {
        $modelFile = Get-ChildItem "Models" -Filter "*$model*.cs"
        if ($modelFile) {
            Write-Host "  ✓ $model model found" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ $model model not found" -ForegroundColor Yellow
        }
    }
}

# Views
if (Test-Path "Views") {
    $viewFolders = Get-ChildItem "Views" -Directory
    Write-Host "✓ View folders: $($viewFolders.Count)" -ForegroundColor Green
    foreach ($folder in $viewFolders) {
        Write-Host "  - $($folder.Name)" -ForegroundColor Gray
    }
}

Write-Host ""

# 8. Dependencies Analysis
Write-Host "8. DEPENDENCIES ANALYSIS" -ForegroundColor Yellow
Write-Host "----------------------------------------"

if (Test-Path "packages") {
    $packageFolders = Get-ChildItem "packages" -Directory
    Write-Host "✓ NuGet packages folder found ($($packageFolders.Count) packages)" -ForegroundColor Green
} else {
    Write-Host "⚠ packages folder not found" -ForegroundColor Yellow
}

Write-Host ""

# 9. Issues and Recommendations
Write-Host "9. ISSUES AND RECOMMENDATIONS" -ForegroundColor Yellow
Write-Host "----------------------------------------"

$issues = @()
$recommendations = @()

# Check for common issues
if (Test-Path "Web.config") {
    $webConfigContent = Get-Content "Web.config" -Raw
    if ($webConfigContent -match "localhost") {
        $issues += "Web.config contains localhost references"
    }
    if ($webConfigContent -match "AttachDbFilename") {
        $issues += "Web.config uses LocalDB (needs Azure SQL)"
    }
}

if (-not (Test-Path ".github\workflows\main_connect2us.yml")) {
    $issues += "GitHub Actions workflow missing"
}

if (-not (Test-Path "Properties\PublishProfiles")) {
    $issues += "Publish profiles missing"
}

# Display issues
if ($issues.Count -gt 0) {
    Write-Host "ISSUES FOUND:" -ForegroundColor Red
    foreach ($issue in $issues) {
        Write-Host "  ✗ $issue" -ForegroundColor Red
    }
} else {
    Write-Host "✓ No major issues detected" -ForegroundColor Green
}

Write-Host ""

# Display recommendations
$recommendations = @(
    "Configure GitHub secrets for Azure deployment",
    "Set up Azure SQL Database connection strings",
    "Test database migrations locally",
    "Configure application insights for monitoring",
    "Set up staging environment for testing",
    "Review and update connection strings for Azure",
    "Configure custom domain and SSL certificates"
)

Write-Host "RECOMMENDATIONS:" -ForegroundColor Cyan
foreach ($recommendation in $recommendations) {
    Write-Host "  → $recommendation" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "=== DIAGNOSIS COMPLETE ===" -ForegroundColor Green
Write-Host "Review the findings above and address any issues before deployment." -ForegroundColor White