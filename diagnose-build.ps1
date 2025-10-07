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
    $configLines = $content | Where-Object { $_ -match "GlobalSection\(SolutionConfigurationPlatforms\)" -or $_ -match "Debug|Release" }
    
    Write-Host "Found configurations:" -ForegroundColor Green
    foreach ($line in $configLines) {
        if ($line -match "Debug|Release") {
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
    Get-Content $publishProfile | Select-String -Pattern "publishUrl|LastUsedPlatform|LastUsedBuildConfiguration"
} else {
    Write-Host "Publish profile not found!" -ForegroundColor Red
}

# Test MSBuild commands
Write-Host "`n4. Testing MSBuild Commands:" -ForegroundColor Yellow
$testCommands = @(
    "msbuild Connect2Us.2.sln /p:Configuration=Release /p:Platform=\"Any CPU\" /verbosity:minimal",
    "msbuild Connect2Us.2.csproj /p:Configuration=Release /p:Platform=\"AnyCPU\" /verbosity:minimal",
    "msbuild Connect2Us.2.csproj /p:Configuration=Release /p:Platform=\"Any CPU\" /verbosity:minimal"
)

foreach ($cmd in $testCommands) {
    Write-Host "`nTesting: $cmd" -ForegroundColor Cyan
    Write-Host "Note: MSBuild may not be available in this environment"
}

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "Diagnostic Complete" -ForegroundColor Green