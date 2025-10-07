Write-Host "=== Connect2Us Deployment Script ===" -ForegroundColor Green

$DeployPath = "published"

if (!(Test-Path $DeployPath)) {
    Write-Error "Published files not found"
    exit 1
}

Write-Host "✓ Published files found" -ForegroundColor Green

Write-Host "`n=== Application Information ===" -ForegroundColor Yellow
Write-Host "Type: ASP.NET MVC 5"
Write-Host "Framework: .NET Framework 4.7.2"
Write-Host "Database: Azure SQL Database"
Write-Host "Authentication: ASP.NET Identity"

Write-Host "`n=== Deployment Instructions ===" -ForegroundColor Yellow
Write-Host "1. Copy published folder to web server"
Write-Host "2. Ensure .NET Framework 4.7.2 is installed"
Write-Host "3. Configure IIS Application Pool for .NET 4.7.2"
Write-Host "4. Set folder permissions"
Write-Host "5. Update connection strings if needed"

Write-Host "`n=== Ready to Deploy ===" -ForegroundColor Green
$fullPath = (Get-Item $DeployPath).FullName
Write-Host "Location: $fullPath"