# Connect2Us Azure Deployment Script
# This script builds and packages your application for Azure deployment

param(
    [string]$Configuration = "Release",
    [string]$Platform = "AnyCPU",
    [string]$OutputDir = ".\published"
)

Write-Host "[START] Starting Connect2Us Azure Deployment Build..." -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Check if MSBuild is available
try {
    # Search for MSBuild in common locations
    $msbuildPaths = @(
        "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe",
        "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe",
        "C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe",
        "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\MSBuild.exe"
    )
    
    $msbuildPath = $null
    foreach ($path in $msbuildPaths) {
        if (Test-Path $path) {
            $msbuildPath = $path
            break
        }
    }
    
    if (-not $msbuildPath) {
        Write-Host "[ERROR] MSBuild not found in any expected location" -ForegroundColor Red
        Write-Host "Searched locations:" -ForegroundColor Yellow
        $msbuildPaths | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
        exit 1
    }
    
    Write-Host "[SUCCESS] MSBuild found: $msbuildPath" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Error locating MSBuild: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Build the project
Write-Host "[INFO] Building project..." -ForegroundColor Yellow
$projectFile = "Connect2Us.2.csproj"

# Check if project file exists
if (-not (Test-Path $projectFile)) {
    Write-Host "[ERROR] Project file not found: $projectFile" -ForegroundColor Red
    Write-Host "Current directory: $(Get-Location)" -ForegroundColor Yellow
    Write-Host "Files in current directory:" -ForegroundColor Yellow
    Get-ChildItem | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Gray }
    exit 1
}

Write-Host "[SUCCESS] Project file found: $projectFile" -ForegroundColor Green
Write-Host "Running: MSBuild $projectFile /nologo /verbosity:m /t:Build /p:Configuration=$Configuration /p:Platform=`"$Platform`"" -ForegroundColor Gray

& $msbuildPath $projectFile /nologo /verbosity:m /t:Build /p:Configuration=$Configuration /p:Platform="$Platform"

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Build failed with exit code $LASTEXITCODE" -ForegroundColor Red
    Write-Host $buildResult -ForegroundColor Red
    exit 1
}

Write-Host "[SUCCESS] Build completed successfully!" -ForegroundColor Green

# Create output directory
Write-Host "[INFO] Creating deployment package..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

# Copy essential files for deployment
Write-Host "[INFO] Copying deployment files..." -ForegroundColor Yellow

# Copy directories
$directories = @("bin", "Content", "Scripts", "Views")
foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        Write-Host "[WARNING] Directory not found: $dir" -ForegroundColor Yellow
        if ($dir -eq 'bin') {
            Write-Host "[INFO] 'bin' directory not found. Listing current directory contents:" -ForegroundColor Cyan
            Get-ChildItem | ForEach-Object { Write-Host "  - $($_.Name)" }
        }
        continue
    }
    
    Copy-Item -Path $dir -Destination "$OutputDir\$dir" -Recurse -Force
    Write-Host "[SUCCESS] Copied directory: $dir" -ForegroundColor Green
}

# Copy individual files using wildcards
$filePatterns = @("*.config", "*.asax", "*.ico")
foreach ($pattern in $filePatterns) {
    $files = Get-ChildItem $pattern -ErrorAction SilentlyContinue
    if ($files) {
        foreach ($file in $files) {
            Copy-Item -Path $file.FullName -Destination $OutputDir -Force
            Write-Host "[SUCCESS] Copied file: $($file.Name)" -ForegroundColor Green
        }
    } else {
        Write-Host "[WARNING] No files found matching pattern: $pattern" -ForegroundColor Yellow
    }
}

# Verify the package
Write-Host "[INFO] Verifying deployment package..." -ForegroundColor Yellow
$packageContents = Get-ChildItem $OutputDir -Recurse
Write-Host "[INFO] Package contains $($packageContents.Count) files" -ForegroundColor Cyan

# Check for critical files
$criticalFiles = @("Web.config", "Global.asax", "bin\Connect2Us.2.dll")
$missingFiles = @()

foreach ($file in $criticalFiles) {
    $fullPath = Join-Path $OutputDir $file
    if (-not (Test-Path $fullPath)) {
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host "[ERROR] Missing critical files:" -ForegroundColor Red
    $missingFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}

Write-Host "[SUCCESS] All critical files present!" -ForegroundColor Green

# Display package summary
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "[SUCCESS] Deployment package created successfully!" -ForegroundColor Green
Write-Host "[INFO] Package location: $(Resolve-Path $OutputDir)" -ForegroundColor Cyan
Write-Host "[INFO] Package size: $([math]::Round((Get-ChildItem $OutputDir -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB, 2)) MB" -ForegroundColor Cyan

Write-Host "`n[START] Ready for Azure deployment!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Commit and push changes to trigger GitHub Actions deployment" -ForegroundColor White
Write-Host "2. Or manually deploy using Azure CLI or Azure Portal" -ForegroundColor White
Write-Host "3. Test your application at: https://connect2us-webapp.azurewebsites.net" -ForegroundColor White

