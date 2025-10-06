# Connect2Us Azure Deployment Script
# This script builds and packages your application for Azure deployment

param(
    [string]$Configuration = "Release",
    [string]$Platform = "Any CPU",
    [string]$OutputDir = ".\published"
)

Write-Host "🚀 Starting Connect2Us Azure Deployment Build..." -ForegroundColor Cyan
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
        Write-Host "❌ MSBuild not found in any expected location" -ForegroundColor Red
        Write-Host "Searched locations:" -ForegroundColor Yellow
        $msbuildPaths | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
        exit 1
    }
    
    Write-Host "✅ MSBuild found: $msbuildPath" -ForegroundColor Green
} catch {
    Write-Host "❌ Error locating MSBuild: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Build the project
Write-Host "🔨 Building project..." -ForegroundColor Yellow
$projectFile = "Connect2Us.2.csproj"

# Check if project file exists
if (-not (Test-Path $projectFile)) {
    Write-Host "❌ Project file not found: $projectFile" -ForegroundColor Red
    Write-Host "Current directory: $(Get-Location)" -ForegroundColor Yellow
    Write-Host "Files in current directory:" -ForegroundColor Yellow
    Get-ChildItem | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Gray }
    exit 1
}

Write-Host "✅ Project file found: $projectFile" -ForegroundColor Green
Write-Host "Running: MSBuild $projectFile /nologo /verbosity:m /t:Build /p:Configuration=$Configuration /p:Platform=`"$Platform`"" -ForegroundColor Gray

& $msbuildPath $projectFile /nologo /verbosity:m /t:Build /p:Configuration=$Configuration /p:Platform="$Platform"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed with exit code $LASTEXITCODE" -ForegroundColor Red
    Write-Host $buildResult -ForegroundColor Red
    exit 1
}

Write-Host "✅ Build completed successfully!" -ForegroundColor Green

# Create output directory
Write-Host "📁 Creating deployment package..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

# Copy essential files for deployment
Write-Host "📁 Copying deployment files..." -ForegroundColor Yellow

# Copy directories
$directories = @("bin", "Content", "Scripts", "Views")
foreach ($dir in $directories) {
    if (Test-Path $dir) {
        Copy-Item -Path $dir -Destination "$OutputDir\$dir" -Recurse -Force
        Write-Host "✅ Copied directory: $dir" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Directory not found: $dir" -ForegroundColor Yellow
        if ($dir -eq "bin") {
            Write-Host "📂 Current directory contents:" -ForegroundColor Cyan
            Get-ChildItem | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Gray }
        }
    }
}

# Copy individual files using wildcards
$filePatterns = @("*.config", "*.asax", "*.ico")
foreach ($pattern in $filePatterns) {
    try {
        $files = Get-ChildItem $pattern -ErrorAction SilentlyContinue
        if ($files) {
            foreach ($file in $files) {
                Copy-Item -Path $file.FullName -Destination $OutputDir -Force
                Write-Host "✅ Copied file: $($file.Name)" -ForegroundColor Green
            }
        } else {
            Write-Host "⚠️  No files found matching pattern: $pattern" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "❌ Error copying files matching $pattern`: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Verify the package
Write-Host "🔍 Verifying deployment package..." -ForegroundColor Yellow
$packageContents = Get-ChildItem $OutputDir -Recurse
Write-Host "📦 Package contains $($packageContents.Count) files" -ForegroundColor Cyan

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
    Write-Host "❌ Missing critical files:" -ForegroundColor Red
    $missingFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}

Write-Host "✅ All critical files present!" -ForegroundColor Green

# Display package summary
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "✅ Deployment package created successfully!" -ForegroundColor Green
Write-Host "📁 Package location: $(Resolve-Path $OutputDir)" -ForegroundColor Cyan
Write-Host "📊 Package size: $([math]::Round((Get-ChildItem $OutputDir -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB, 2)) MB" -ForegroundColor Cyan

Write-Host "`n🚀 Ready for Azure deployment!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Commit and push changes to trigger GitHub Actions deployment" -ForegroundColor White
Write-Host "2. Or manually deploy using Azure CLI or Azure Portal" -ForegroundColor White
Write-Host "3. Test your application at: https://connect2us-webapp.azurewebsites.net" -ForegroundColor White