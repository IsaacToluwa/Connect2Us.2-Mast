# Connect2Us Deployment Verification Script
param(
    [switch]$QuickCheck,
    [switch]$FullCheck
)

Write-Host "Connect2Us Deployment Verification" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

$errors = @()
$successCount = 0

function Write-CheckResult {
    param($TestName, $Success, $Message)
    if ($Success) {
        Write-Host "✓ " -ForegroundColor Green -NoNewline
        Write-Host "$TestName - $Message"
        $script:successCount++
    } else {
        Write-Host "✗ " -ForegroundColor Red -NoNewline
        Write-Host "$TestName - $Message"
        $script:errors += "$TestName : $Message"
    }
}

# Check Essential Files
Write-Host "`nChecking Essential Files..." -ForegroundColor Yellow

$essentialFiles = @(
    @(".github\workflows\main_connect2us.yml", "GitHub Actions Workflow"),
    @("Properties\PublishProfiles\FileSystem.pubxml", "MSBuild Publish Profile"),
    @("Web.config", "Base Configuration"),
    @("Web.Release.config", "Production Configuration"),
    @("Connect2Us.2.csproj", "Project File"),
    @("Global.asax", "Application Entry Point"),
    @("packages.config", "NuGet Packages")
)

foreach ($fileInfo in $essentialFiles) {
    $filePath = $fileInfo[0]
    $fileDesc = $fileInfo[1]
    
    if (Test-Path $filePath) {
        Write-CheckResult $fileDesc $true "Found at $filePath"
    } else {
        Write-CheckResult $fileDesc $false "Missing at $filePath"
    }
}

# Check Directory Structure
Write-Host "`nChecking Directory Structure..." -ForegroundColor Yellow

$essentialDirs = @(
    @("Views", "MVC Views"),
    @("Controllers", "MVC Controllers"),
    @("Models", "Data Models"),
    @("Content", "CSS/Images"),
    @("Scripts", "JavaScript Files"),
    @("fonts", "Font Files"),
    @("App_Start", "Application Startup")
)

foreach ($dirInfo in $essentialDirs) {
    $dirPath = $dirInfo[0]
    $dirDesc = $dirInfo[1]
    
    if (Test-Path $dirPath) {
        Write-CheckResult $dirDesc $true "Directory exists"
    } else {
        Write-Host "⚠ $dirDesc - Directory missing (may be optional)" -ForegroundColor Yellow
    }
}

# Summary
Write-Host "`nDeployment Verification Summary" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

Write-Host "✅ Successful Checks: $successCount" -ForegroundColor Green
Write-Host "❌ Errors Found: $($errors.Count)" -ForegroundColor Red

if ($errors.Count -gt 0) {
    Write-Host "Errors:" -ForegroundColor Red
    foreach ($error in $errors) {
        Write-Host "  - $error" -ForegroundColor Red
    }
}

# Final Recommendation
Write-Host "`nDeployment Readiness: " -ForegroundColor Cyan -NoNewline

if ($errors.Count -eq 0) {
    Write-Host "READY FOR DEPLOYMENT" -ForegroundColor Green
    Write-Host "`nYour deployment configuration looks good!" -ForegroundColor Green
    Write-Host "You can safely push to GitHub to trigger deployment." -ForegroundColor Green
} else {
    Write-Host "NEEDS ATTENTION" -ForegroundColor Red
    Write-Host "`nPlease fix the errors above before deploying." -ForegroundColor Red
}