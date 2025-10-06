# Connect2Us PowerShell Script Syntax Validation
# This script validates the syntax of all PowerShell deployment scripts

param(
    [switch]$Verbose = $false,
    [switch]$FixIssues = $false
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Script files to validate
$scriptFiles = @(
    "Deploy-ToAzure.ps1",
    "Create-AzureResources.ps1", 
    "Migrate-Database.ps1"
)

# Function to write colored output
function Write-Status {
    param(
        [string]$Message,
        [string]$Status = "INFO"
    )
    
    $colors = @{
        "INFO" = "White"
        "SUCCESS" = "Green"
        "WARNING" = "Yellow"
        "ERROR" = "Red"
        "VERBOSE" = "Cyan"
    }
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] [$Status] $Message" -ForegroundColor $colors[$Status]
}

# Function to test PowerShell syntax
function Test-PowerShellSyntax {
    param([string]$FilePath)
    
    Write-Status "Validating syntax: $FilePath" "INFO"
    
    try {
        # Parse the script to check for syntax errors
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $FilePath -Raw), [ref]$null)
        
        # Test script execution with -WhatIf (if applicable)
        $scriptContent = Get-Content $FilePath -Raw
        
        # Check for common issues
        $issues = @()
        
        # Check for missing parameter declarations
        if ($scriptContent -notmatch 'param\s*\(') {
            $issues += "Script does not have a param block (recommended for parameter validation)"
        }
        
        # Check for error handling
        if ($scriptContent -notmatch '\$ErrorActionPreference\s*=\s*["'']Stop["'']') {
            $issues += "Script does not set ErrorActionPreference to 'Stop' (recommended for proper error handling)"
        }
        
        # Check for help documentation
        if ($scriptContent -notmatch '<#.*#>' -and $scriptContent -notmatch '\.SYNOPSIS') {
            $issues += "Script lacks help documentation (consider adding .SYNOPSIS, .DESCRIPTION, etc.)"
        }
        
        # Check for Write-Output vs Write-Host usage
        if ($scriptContent -match 'Write-Output.*-ForegroundColor') {
            $issues += "Write-Output does not support -ForegroundColor parameter (use Write-Host instead)"
        }
        
        # Check for Azure CLI dependency
        if ($scriptContent -match 'az\s+' -and $scriptContent -notmatch 'Test-AzureCLI|az\s+--version') {
            $issues += "Script uses Azure CLI commands but does not check if Azure CLI is installed"
        }
        
        # Check for hardcoded credentials
        if ($scriptContent -match '(password|pwd|secret)\s*=\s*["''][^"'']*["'']') {
            $issues += "Script appears to have hardcoded credentials (security risk)"
        }
        
        # Check for proper connection string handling
        if ($scriptContent -match 'connectionString.*password.*Test@123') {
            $issues += "Script contains hardcoded connection string with password"
        }
        
        # Check for deprecated cmdlets
        if ($scriptContent -match 'Write-Verbose.*-ForegroundColor') {
            $issues += "Write-Verbose does not support -ForegroundColor parameter"
        }
        
        # Check for proper function definitions
        if ($scriptContent -match 'function\s+\w+\s*\([^)]*\)\s*\{' -and $scriptContent -notmatch 'function\s+\w+\s*\([^)]*\)\s*\{\s*\[CmdletBinding\(\)\]') {
            $issues += "Functions should use [CmdletBinding()] for advanced function features"
        }
        
        return @{
            FilePath = $FilePath
            IsValid = $true
            Issues = $issues
            ErrorMessage = $null
        }
    }
    catch {
        return @{
            FilePath = $FilePath
            IsValid = $false
            Issues = @()
            ErrorMessage = $_.Exception.Message
        }
    }
}

# Function to validate script parameters
function Test-ScriptParameters {
    param([string]$FilePath)
    
    Write-Status "Validating parameters: $FilePath" "INFO"
    
    try {
        # Get script parameters
        $scriptInfo = Get-Command $FilePath -ErrorAction Stop
        
        $paramIssues = @()
        
        # Check for mandatory parameters
        foreach ($param in $scriptInfo.Parameters.Values) {
            if ($param.Attributes.Mandatory -and -not $param.Name.StartsWith('Verbose')) {
                Write-Status "Found mandatory parameter: $($param.Name)" "VERBOSE"
            }
        }
        
        # Check for help in parameters
        if ($scriptInfo.Parameters.Count -gt 0) {
            $hasHelp = $false
            foreach ($param in $scriptInfo.Parameters.Values) {
                if ($param.HelpMessage) {
                    $hasHelp = $true
                    break
                }
            }
            
            if (-not $hasHelp) {
                $paramIssues += "Parameters lack help messages (use [Parameter(HelpMessage='...')])"
            }
        }
        
        return @{
            FilePath = $FilePath
            Parameters = $scriptInfo.Parameters
            Issues = $paramIssues
            ErrorMessage = $null
        }
    }
    catch {
        return @{
            FilePath = $FilePath
            Parameters = $null
            Issues = @()
            ErrorMessage = $_.Exception.Message
        }
    }
}

# Function to check for security issues
function Test-SecurityIssues {
    param([string]$FilePath)
    
    Write-Status "Checking security issues: $FilePath" "INFO"
    
    $scriptContent = Get-Content $FilePath -Raw
    $securityIssues = @()
    
    # Check for hardcoded passwords (excluding parameters, variables, and legitimate uses)
    $passwordPatterns = @(
        'password\s*=\s*["''][^"'']*["'']',
        'pwd\s*=\s*["''][^"'']*["'']',
        'secret\s*=\s*["''][^"'']*["'']',
        'apikey\s*=\s*["''][^"'']*["'']',
        'api_key\s*=\s*["''][^"'']*["'']'
    )
    
    foreach ($pattern in $passwordPatterns) {
        if ($scriptContent -match $pattern) {
            # Additional check to exclude legitimate uses
            $lines = $scriptContent -split "`n"
            foreach ($line in $lines) {
                if ($line -match $pattern -and 
                    $line -notmatch '\[Parameter\]' -and 
                    $line -notmatch '\$\w+\s*=\s*\$\w+' -and
                    $line -notmatch 'param\s*\(' -and
                    $line -notmatch 'function\s+\w+' -and
                    $line -notmatch 'connectionString.*\$\w+' -and
                    $line -notmatch 'Password=\$\w+' -and
                    $line -notmatch '\$requiredKeywords.*Password=' -and
                    $line -notmatch '\$.*=\s*@\(.*Password=' -and
                    $line -notmatch 'ErrorMessage.*password') {
                    $securityIssues += "Potential hardcoded credential found: $pattern"
                    break
                }
            }
        }
    }
    
    # Check for insecure protocols
    if ($scriptContent -match 'http://.*\.database\.windows\.net') {
        $securityIssues += "Insecure HTTP protocol used for database connection (should be TCP)"
    }
    
    # Check for plaintext connection strings (excluding parameter definitions and legitimate uses)
    $connectionStringLines = $scriptContent -split "`n"
    foreach ($line in $connectionStringLines) {
        if ($line -match 'connectionString.*password.*[^}]*["'']' -and
            $line -notmatch '\[Parameter\]' -and
            $line -notmatch 'param\s*\(' -and
            $line -notmatch '#.*connectionString' -and
            $line -notmatch '\$\w+.*password.*\$\w+' -and  # Exclude variable interpolation
            $line -notmatch 'Password=\$\w+') {  # Exclude parameterized passwords
            $securityIssues += "Potential plaintext connection string with password"
            break
        }
    }
    
    # Check for execution policies
    if ($scriptContent -match 'Set-ExecutionPolicy.*-ExecutionPolicy\s+(Unrestricted|Bypass)') {
        $securityIssues += "Script sets execution policy to Unrestricted or Bypass (security risk)"
    }
    
    return $securityIssues
}

# Function to generate report
function New-ValidationReport {
    param([array]$Results)
    
    Write-Status "Generating validation report..." "INFO"
    
    $report = @()
    $report += "PowerShell Script Validation Report"
    $report += "==================================="
    $report += "Generated: $(Get-Date)"
    $report += ""
    
    $totalIssues = 0
    $totalErrors = 0
    $totalSecurityIssues = 0
    
    foreach ($result in $Results) {
        $report += "File: $($result.FilePath)"
        $report += "Syntax Valid: $($result.SyntaxResult.IsValid)"
        
        if ($result.SyntaxResult.ErrorMessage) {
            $report += "Syntax Error: $($result.SyntaxResult.ErrorMessage)"
            $totalErrors++
        }
        
        if ($result.SyntaxResult.Issues.Count -gt 0) {
            $report += "Issues Found:"
            foreach ($issue in $result.SyntaxResult.Issues) {
                $report += "  - $issue"
                $totalIssues++
            }
        }
        
        if ($result.SecurityIssues.Count -gt 0) {
            $report += "Security Issues:"
            foreach ($issue in $result.SecurityIssues) {
                $report += "  - SECURITY: $issue"
                $totalSecurityIssues++
            }
        }
        
        $report += ""
    }
    
    $report += "Summary"
    $report += "======="
    $report += "Total Scripts: $($Results.Count)"
    $report += "Syntax Errors: $totalErrors"
    $report += "General Issues: $totalIssues"
    $report += "Security Issues: $totalSecurityIssues"
    
    return $report -join "`n"
}

# Main execution
try {
    Write-Status "Starting PowerShell Script Validation..." "INFO"
    Write-Status "=========================================" "INFO"
    
    $validationResults = @()
    
    foreach ($scriptFile in $scriptFiles) {
        if (-not (Test-Path $scriptFile)) {
            Write-Status "Script file not found: $scriptFile" "WARNING"
            continue
        }
        
        Write-Status "Processing: $scriptFile" "INFO"
        
        # Test syntax
        $syntaxResult = Test-PowerShellSyntax -FilePath $scriptFile
        
        # Test parameters
        $paramResult = Test-ScriptParameters -FilePath $scriptFile
        
        # Check security issues
        $securityIssues = Test-SecurityIssues -FilePath $scriptFile
        
        $validationResults += @{
            FilePath = $scriptFile
            SyntaxResult = $syntaxResult
            ParameterResult = $paramResult
            SecurityIssues = $securityIssues
        }
        
        if ($Verbose) {
            Write-Status "Syntax validation: $($syntaxResult.IsValid)" "VERBOSE"
            if ($syntaxResult.Issues.Count -gt 0) {
                foreach ($issue in $syntaxResult.Issues) {
                    Write-Status "  Issue: $issue" "VERBOSE"
                }
            }
            if ($securityIssues.Count -gt 0) {
                foreach ($issue in $securityIssues) {
                    Write-Status "  Security: $issue" "VERBOSE"
                }
            }
        }
    }
    
    # Generate report
    $report = New-ValidationReport -Results $validationResults
    
    # Save report
    $reportPath = "validation-report.txt"
    Set-Content -Path $reportPath -Value $report
    
    Write-Status "Validation report saved to: $reportPath" "SUCCESS"
    
    # Display summary
    Write-Status "=========================================" "INFO"
    Write-Status "Validation Summary:" "INFO"
    
    $syntaxErrors = ($validationResults | Where-Object { -not $_.SyntaxResult.IsValid }).Count
    $totalIssues = ($validationResults | ForEach-Object { $_.SyntaxResult.Issues.Count } | Measure-Object -Sum).Sum
    $totalSecurityIssues = ($validationResults | ForEach-Object { $_.SecurityIssues.Count } | Measure-Object -Sum).Sum
    
    Write-Status "Scripts processed: $($validationResults.Count)" "INFO"
    Write-Status "Syntax errors: $syntaxErrors" $(if ($syntaxErrors -gt 0) { "ERROR" } else { "SUCCESS" })
    Write-Status "General issues: $totalIssues" $(if ($totalIssues -gt 0) { "WARNING" } else { "SUCCESS" })
    Write-Status "Security issues: $totalSecurityIssues" $(if ($totalSecurityIssues -gt 0) { "ERROR" } else { "SUCCESS" })
    
    if ($syntaxErrors -gt 0 -or $totalSecurityIssues -gt 0) {
        Write-Status "Validation failed with critical issues!" "ERROR"
        exit 1
    } elseif ($totalIssues -gt 0) {
        Write-Status "Validation completed with warnings." "WARNING"
        exit 0
    } else {
        Write-Status "All scripts validated successfully!" "SUCCESS"
        exit 0
    }
    
}
catch {
    Write-Status "Validation script failed: $($_.Exception.Message)" "ERROR"
    exit 1
}