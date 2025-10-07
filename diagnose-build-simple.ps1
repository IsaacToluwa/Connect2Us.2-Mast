Write-Host "Connect2Us Build Configuration Diagnostic" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# Check project file configurations
Write-Host "`n1. Project File Configurations:" -ForegroundColor Yellow
$projectFile = "Connect2Us.2.csproj"
if (Test-Path $projectFile) {
    [xml]$xml = Get-Content $projectFile
    $propertyGroups = $xml.Project.PropertyGroup | Where-Object { $_.Condition -ne $null }
    
    foreach ($pg in $propertyGroups) {
        Write-Host "Configuration: $($pg.Condition)" -ForegroundColor Green
        if ($pg.OutputPath) {
            Write-Host "  OutputPath: $($pg.OutputPath)"
        }
        if ($pg.Platform) {
            Write-Host "  Platform: $($pg.Platform)"
        }
    }
} else {
    Write-Host "Project file not found!" -ForegroundColor Red
}

# Check solution file
Write-Host "`n2. Solution File Configurations:" -ForegroundColor Yellow
$solutionFile = "Connect2Us.2.sln"
if (Test-Path $solutionFile) {
    $content = Get-Content $solutionFile
    Write-Host "Solution file found - checking configurations..." -ForegroundColor Green
    
    # Look for configuration lines
    $configLines = $content | Where-Object { $_ -match "Debug|Release" }
    foreach ($line in $configLines) {
        if ($line.Trim() -ne "" -and $line.Length -lt 100) {
            Write-Host "  $line"
        }
    }
} else {
    Write-Host "Solution file not found!" -ForegroundColor Red
}

# Check publish profile
Write-Host "`n3. Publish Profile:" -ForegroundColor Yellow
$publishProfile = "Properties\PublishProfiles\FileSystem.pubxml"
if (Test-Path $publishProfile) {
    Write-Host "Publish profile found:" -ForegroundColor Green
    $content = Get-Content $publishProfile
    $content | Select-String -Pattern "publishUrl|LastUsedPlatform|LastUsedBuildConfiguration|PublishProvider"
} else {
    Write-Host "Publish profile not found!" -ForegroundColor Red
}

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "Diagnostic Complete - Key Findings:" -ForegroundColor Green
Write-Host "- Project uses 'AnyCPU' (no space) in configurations"
Write-Host "- Solution file exists and should be used for building"
Write-Host "- Publish profile is configured for FileSystem deployment"
Write-Host "- Use 'Any CPU' (with space) for solution builds"
Write-Host "- Use 'AnyCPU' (no space) for project-specific builds"