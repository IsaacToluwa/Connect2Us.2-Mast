@echo off
echo Testing PowerShell script execution...
powershell -Command "Get-ExecutionPolicy"
powershell -Command "Test-Path 'verify-deployment.ps1'"
powershell -ExecutionPolicy Bypass -Command ".\verify-deployment.ps1 -QuickCheck"
pause