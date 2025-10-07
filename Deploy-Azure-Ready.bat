@echo off
echo === AZURE DEPLOYMENT PREPARATION ===
echo.

REM Check if Web.config exists
if exist "Web.config" (
    copy "Web.config" "Web.config.backup" >nul
    echo ✓ Created backup of Web.config
) else (
    echo ❌ Web.config not found!
    exit /b 1
)

echo.
echo Updating Web.config for Azure SQL...

REM Create temporary file for updated config
set "tempFile=Web_temp.config"

REM Read Web.config and replace Azure SQL settings
(
for /f "delims=" %%i in ('type "Web.config"') do (
    set "line=%%i"
    
    REM Replace LocalDB server with Azure SQL server
    echo %%i | findstr /C:"data source=(localdb)\MSSQLLocalDB" >nul
    if !errorlevel! equ 0 (
        set "line=!line:data source=(localdb)\MSSQLLocalDB=data source=demo-server.database.windows.net!"
    )
    
    REM Replace database name
    echo %%i | findstr /C:"initial catalog=Connect2US" >nul
    if !errorlevel! equ 0 (
        set "line=!line:initial catalog=Connect2US=Database=Connect2US!"
    )
    
    REM Replace integrated security
    echo %%i | findstr /C:"integrated security=True" >nul
    if !errorlevel! equ 0 (
        set "line=!line:integrated security=True=User ID=sqladmin;Password=DemoPassword123!!"
    )
    
    REM Replace MultipleActiveResultSets
    echo %%i | findstr /C:"MultipleActiveResultSets=True;App=EntityFramework" >nul
    if !errorlevel! equ 0 (
        set "line=!line:MultipleActiveResultSets=True;App=EntityFramework=Encrypt=True;TrustServerCertificate=False;Connection Timeout=30!"
    )
    
    REM Replace LocalDbConnectionFactory
    echo %%i | findstr /C:"LocalDbConnectionFactory" >nul
    if !errorlevel! equ 0 (
        set "line=!line:LocalDbConnectionFactory=SqlConnectionFactory!"
    )
    
    REM Remove mssqllocaldb parameter
    echo %%i | findstr /C:"<parameter value=""mssqllocaldb"" />" >nul
    if !errorlevel! equ 0 (
        REM Skip this line
        goto :skipLine
    )
    
    echo !line!
    :skipLine
)
) > "%tempFile%"

REM Replace original file
move /y "%tempFile%" "Web.config" >nul
echo ✓ Web.config updated successfully

echo.
echo Creating deployment package...

REM Create deployment directory
if exist "AzureDeployment" rmdir /s /q "AzureDeployment"
mkdir "AzureDeployment"

REM Copy essential files
echo  ✓ Copied Web.config
copy "Web.config" "AzureDeployment\" >nul
if exist "Global.asax" copy "Global.asax" "AzureDeployment\" >nul
if exist "Connect2Us.2.csproj" copy "Connect2Us.2.csproj" "AzureDeployment\" >nul
if exist "packages.config" copy "packages.config" "AzureDeployment\" >nul

REM Copy directories
if exist "Controllers" xcopy /s /i /q "Controllers" "AzureDeployment\Controllers" >nul
echo  ✓ Copied Controllers directory
if exist "Models" xcopy /s /i /q "Models" "AzureDeployment\Models" >nul
echo  ✓ Copied Models directory
if exist "Views" xcopy /s /i /q "Views" "AzureDeployment\Views" >nul
echo  ✓ Copied Views directory
if exist "Content" xcopy /s /i /q "Content" "AzureDeployment\Content" >nul
echo  ✓ Copied Content directory
if exist "Scripts" xcopy /s /i /q "Scripts" "AzureDeployment\Scripts" >nul
echo  ✓ Copied Scripts directory
if exist "App_Start" xcopy /s /i /q "App_Start" "AzureDeployment\App_Start" >nul
echo  ✓ Copied App_Start directory
if exist "App_Data" xcopy /s /i /q "App_Data" "AzureDeployment\App_Data" >nul
echo  ✓ Copied App_Data directory

echo.
echo ✓ Deployment package created in AzureDeployment

echo.
echo Validating configuration...

REM Check for localhost references
findstr /C:"localhost" "Web.config" >nul
if %errorlevel% equ 0 (
    echo ⚠ Localhost references still present
) else (
    echo ✓ No localhost references found
)

REM Check for LocalDB references
findstr /C:"LocalDB" "Web.config" >nul
if %errorlevel% equ 0 (
    echo ⚠ LocalDB references still present
) else (
    echo ✓ No LocalDB references found
)

echo.
echo === DEPLOYMENT PREPARATION COMPLETE ===
echo.
echo ✓ Project is ready for Azure deployment!
echo.
echo Next steps:
echo 1. Review the updated Web.config file
echo 2. Set up GitHub secrets using Setup-GitHub-Secrets.ps1
echo 3. Deploy to Azure using GitHub Actions
echo.
echo Deployment package created in: AzureDeployment

pause