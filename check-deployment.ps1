Write-Host "Connect2Us Deployment Check" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan

$errors = 0
$success = 0

function Test-File {
    param($Path, $Description)
    if (Test-Path $Path) {
        Write-Host "✓ $Description - Found" -ForegroundColor Green
        $script:success++
    } else {
        Write-Host "✗ $Description - Missing" -ForegroundColor Red
        $script:errors++
    }
}

# Check essential files
Test-File ".github\workflows\main_connect2us.yml" "GitHub Workflow"
Test-File "Properties\PublishProfiles\FileSystem.pubxml" "Publish Profile"
Test-File "Web.config" "Base Configuration"
Test-File "Web.Release.config" "Production Configuration"
Test-File "Connect2Us.2.csproj" "Project File"
Test-File "Global.asax" "Application Entry Point"

# Check directories
$dirs = @("Views", "Controllers", "Models", "Content", "Scripts", "fonts")
foreach ($dir in $dirs) {
    if (Test-Path $dir) {
        Write-Host "✓ $dir Directory - Found" -ForegroundColor Green
        $script:success++
    } else {
        Write-Host "⚠ $dir Directory - Missing (may be optional)" -ForegroundColor Yellow
    }
}

# Summary
Write-Host "`nResults:" -ForegroundColor Cyan
Write-Host "✅ Success: $success" -ForegroundColor Green
Write-Host "❌ Errors: $errors" -ForegroundColor Red

if ($errors -eq 0) {
    Write-Host "`n🎯 Ready for deployment!" -ForegroundColor Green
} else {
    Write-Host "`n⚠️  Fix errors before deploying" -ForegroundColor Red
}