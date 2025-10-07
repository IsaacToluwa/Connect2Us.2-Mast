@echo off
echo === CONNECT2US PROJECT DIAGNOSIS ===
echo.

echo PROJECT STRUCTURE:
echo.
echo Checking folders...
if exist "Controllers" (echo ✓ Controllers folder found) else (echo ✗ Controllers folder missing)
if exist "Models" (echo ✓ Models folder found) else (echo ✗ Models folder missing)
if exist "Views" (echo ✓ Views folder found) else (echo ✗ Views folder missing)
if exist "App_Data" (echo ✓ App_Data folder found) else (echo ✗ App_Data folder missing)
if exist "App_Start" (echo ✓ App_Start folder found) else (echo ✗ App_Start folder missing)
if exist "Content" (echo ✓ Content folder found) else (echo ✗ Content folder missing)
if exist "Scripts" (echo ✓ Scripts folder found) else (echo ✗ Scripts folder missing)

echo.
echo CONFIGURATION FILES:
echo.
if exist "Web.config" (echo ✓ Web.config found) else (echo ✗ Web.config missing)
if exist "packages.config" (echo ✓ packages.config found) else (echo ⚠ packages.config not found)

echo.
echo GITHUB ACTIONS:
echo.
if exist ".github\workflows\main_connect2us.yml" (echo ✓ GitHub Actions workflow found) else (echo ✗ GitHub Actions workflow missing)

echo.
echo AZURE CONFIGURATION:
echo.
if exist "Properties\PublishProfiles" (echo ✓ Publish profiles directory found) else (echo ⚠ Publish profiles missing)

echo.
echo DATABASE SETUP:
echo.
if exist "Migrations" (echo ✓ Migrations folder found) else (echo ⚠ Migrations folder missing)
if exist "MigrationRunner" (echo ✓ MigrationRunner project found) else (echo ⚠ MigrationRunner missing)

echo.
echo KEY ISSUES:
echo.
set issues=0

if exist "Web.config" (
    findstr /C:"localhost" "Web.config" >nul
    if %errorlevel%==0 (
        echo ⚠ Localhost references found in Web.config
        set issues=1
    )
    
    findstr /C:"AttachDbFilename" "Web.config" >nul
    if %errorlevel%==0 (
        echo ⚠ LocalDB usage detected - needs Azure SQL
        set issues=1
    )
)

if not exist ".github\workflows\main_connect2us.yml" (
    echo ⚠ GitHub Actions workflow missing
    set issues=1
)

if not exist "Properties\PublishProfiles" (
    echo ⚠ Azure publish profiles missing
    set issues=1
)

if %issues%==0 (
    echo ✓ No major issues detected
)

echo.
echo === DIAGNOSIS COMPLETE ===
echo Review the findings above and address any issues before deployment.
pause