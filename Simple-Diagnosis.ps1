# Simple Project Diagnosis Script
Write-Host "=== CONNECT2US PROJECT DIAGNOSIS ===" -ForegroundColor Cyan
Write-Host ""

# Project Structure
Write-Host "PROJECT STRUCTURE:" -ForegroundColor Yellow
$folders = @("Controllers", "Models", "Views", "App_Data", "App_Start", "Content", "Scripts")
foreach ($folder in $folders) {
    if (Test-Path $folder) {
        Write-Host "✓ $folder exists" -ForegroundColor Green
    } else {
        Write-Host "✗ $folder missing" -ForegroundColor Red
    }
}

Write-Host ""

# Configuration Files
Write-Host "CONFIGURATION FILES:" -ForegroundColor Yellow
$configFiles = @("Web.config", "packages.config")
foreach ($file in $configFiles) {
    if (Test-Path $file) {
        Write-Host "✓ $file found" -ForegroundColor Green
    } else {
        Write-Host "⚠ $file not found" -ForegroundColor Yellow
    }
}

Write-Host ""

# GitHub Actions
Write-Host "GITHUB ACTIONS:" -ForegroundColor Yellow
if (Test-Path ".github\workflows\main_connect2us.yml") {
    Write-Host "✓ Workflow file found" -ForegroundColor Green
} else {
    Write-Host "✗ Workflow file missing" -ForegroundColor Red
}

Write-Host ""

# Azure Configuration
Write-Host "AZURE CONFIGURATION:" -ForegroundColor Yellow
if (Test-Path "Properties\PublishProfiles") {
    Write-Host "✓ Publish profiles directory exists" -ForegroundColor Green
} else {
    Write-Host "⚠ Publish profiles missing" -ForegroundColor Yellow
}

Write-Host ""

# Database Setup
Write-Host "DATABASE SETUP:" -ForegroundColor Yellow
if (Test-Path "Migrations") {
    Write-Host "✓ Migrations folder found" -ForegroundColor Green
} else {
    Write-Host "⚠ Migrations folder missing" -ForegroundColor Yellow
}

if (Test-Path "MigrationRunner") {
    Write-Host "✓ MigrationRunner project found" -ForegroundColor Green
} else {
    Write-Host "⚠ MigrationRunner missing" -ForegroundColor Yellow
}

Write-Host ""

# Key Issues Check
Write-Host "KEY ISSUES:" -ForegroundColor Yellow
$issues = @()

if (Test-Path "Web.config") {
    $content = Get-Content "Web.config" -Raw
    if ($content -match "localhost") {
        $issues += "Localhost references in Web.config"
    }
    if ($content -match "AttachDbFilename") {
        $issues += "LocalDB usage detected (needs Azure SQL)"
    }
}

if (-not (Test-Path ".github\workflows\main_connect2us.yml")) {
    $issues += "GitHub Actions workflow missing"
}

if (-not (Test-Path "Properties\PublishProfiles")) {
    $issues += "Azure publish profiles missing"
}

if ($issues.Count -gt 0) {
    foreach ($issue in $issues) {
        Write-Host "⚠ $issue" -ForegroundColor Yellow
    }
} else {
    Write-Host "✓ No major issues detected" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== DIAGNOSIS COMPLETE ===" -ForegroundColor Green