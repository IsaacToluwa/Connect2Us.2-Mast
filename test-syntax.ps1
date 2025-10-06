$content = Get-Content .\Deploy-ToAzure.ps1 -Raw
try {
    $null = [scriptblock]::Create($content)
    Write-Host "Syntax OK" -ForegroundColor Green
} catch {
    Write-Host "Syntax Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Error details: $($_.Exception)" -ForegroundColor Yellow
}