#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Setup script for k6 performance testing integration
    
.DESCRIPTION
    This script helps set up k6 performance testing for the Java application.
    It can install k6, verify Docker, and run initial tests.
    
.PARAMETER InstallK6
    Attempt to install k6 using chocolatey (Windows)
    
.PARAMETER VerifySetup
    Run verification tests to ensure everything is working
    
.PARAMETER RunSampleTest
    Run a sample test to verify the integration
    
.EXAMPLE
    .\setup-k6.ps1 -InstallK6 -VerifySetup
    
.EXAMPLE
    .\setup-k6.ps1 -RunSampleTest
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$InstallK6,
    
    [Parameter(Mandatory=$false)]
    [switch]$VerifySetup,
    
    [Parameter(Mandatory=$false)]
    [switch]$RunSampleTest,
    
    [Parameter(Mandatory=$false)]
    [string]$BaseUrl = "http://localhost:8080"
)

Write-Host "=== k6 Performance Testing Setup ===" -ForegroundColor Green
Write-Host ""

# Function to check if command exists
function Test-Command {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

# Check PowerShell version
$psVersion = $PSVersionTable.PSVersion
Write-Host "PowerShell version: $psVersion" -ForegroundColor Cyan
if ($psVersion.Major -lt 5) {
    Write-Warning "PowerShell 5.0 or later is recommended"
}

# Check Docker
$dockerAvailable = Test-Command "docker"
if ($dockerAvailable) {
    $dockerVersion = docker --version
    Write-Host "Docker: $dockerVersion" -ForegroundColor Green
} else {
    Write-Host "Docker: Not found" -ForegroundColor Red
    Write-Warning "Docker is required for k6 tests if k6 is not installed locally"
}

# Check k6
$k6Available = Test-Command "k6"
if ($k6Available) {
    $k6Version = k6 version
    Write-Host "k6: $k6Version" -ForegroundColor Green
} else {
    Write-Host "k6: Not found" -ForegroundColor Yellow
    if ($InstallK6) {
        Write-Host "Attempting to install k6..." -ForegroundColor Cyan
        
        # Check if Chocolatey is available
        if (Test-Command "choco") {
            try {
                choco install k6 -y
                Write-Host "k6 installed successfully via Chocolatey!" -ForegroundColor Green
                $k6Available = $true
            } catch {
                Write-Warning "Failed to install k6 via Chocolatey: $($_.Exception.Message)"
            }
        } else {
            Write-Warning "Chocolatey not found. Please install k6 manually or use Docker."
            Write-Host "Manual installation options:" -ForegroundColor Yellow
            Write-Host "1. Download from: https://github.com/grafana/k6/releases" -ForegroundColor Yellow
            Write-Host "2. Install via Chocolatey: choco install k6" -ForegroundColor Yellow
            Write-Host "3. Use Docker: docker run grafana/k6 --version" -ForegroundColor Yellow
        }
    }
}

Write-Host ""

# Verify directory structure
Write-Host "Verifying k6 directory structure..." -ForegroundColor Yellow

$requiredDirs = @("k6-tests\scripts", "k6-tests\configs", "k6-tests\results")
$requiredFiles = @(
    "k6-tests\scripts\load-test.js",
    "k6-tests\scripts\stress-test.js", 
    "k6-tests\scripts\spike-test.js",
    "k6-tests\scripts\smoke-test.js",
    "k6-tests\configs\dev.json",
    "k6-tests\configs\staging.json",
    "k6-tests\configs\production.json",
    "k6-tests\run-k6-tests.ps1",
    "k6-tests\process-results.ps1"
)

$allGood = $true

foreach ($dir in $requiredDirs) {
    if (Test-Path $dir) {
        Write-Host "✓ Directory: $dir" -ForegroundColor Green
    } else {
        Write-Host "✗ Directory missing: $dir" -ForegroundColor Red
        $allGood = $false
    }
}

foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "✓ File: $file" -ForegroundColor Green
    } else {
        Write-Host "✗ File missing: $file" -ForegroundColor Red
        $allGood = $false
    }
}

if ($allGood) {
    Write-Host "✓ All required files and directories found!" -ForegroundColor Green
} else {
    Write-Host "✗ Some files or directories are missing" -ForegroundColor Red
    Write-Warning "Please ensure all k6 test files are present"
}

Write-Host ""

# Verify setup
if ($VerifySetup) {
    Write-Host "Running setup verification..." -ForegroundColor Yellow
    
    # Test Docker k6 if k6 is not available locally
    if (!$k6Available -and $dockerAvailable) {
        Write-Host "Testing Docker k6 setup..." -ForegroundColor Cyan
        try {
            $dockerK6Version = docker run --rm grafana/k6:latest version
            Write-Host "Docker k6: $dockerK6Version" -ForegroundColor Green
        } catch {
            Write-Host "Docker k6 test failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    # Check if application is running (if BaseUrl is localhost)
    if ($BaseUrl -like "*localhost*") {
        Write-Host "Testing application availability at $BaseUrl..." -ForegroundColor Cyan
        try {
            $response = Invoke-WebRequest -Uri "$BaseUrl/actuator/health" -TimeoutSec 5 -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                Write-Host "✓ Application is running and healthy" -ForegroundColor Green
            } else {
                Write-Host "! Application responded with status: $($response.StatusCode)" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "✗ Application not accessible: $($_.Exception.Message)" -ForegroundColor Red
            Write-Warning "Make sure your Java application is running on $BaseUrl"
        }
    }
}

# Run sample test
if ($RunSampleTest) {
    Write-Host "Running sample test..." -ForegroundColor Yellow
    
    if (Test-Path "k6-tests\run-k6-tests.ps1") {
        try {
            Write-Host "Executing: .\k6-tests\run-k6-tests.ps1 -TestType smoke -Environment dev -BaseUrl $BaseUrl" -ForegroundColor Cyan
            & ".\k6-tests\run-k6-tests.ps1" -TestType smoke -Environment dev -BaseUrl $BaseUrl -Verbose
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✓ Sample test completed successfully!" -ForegroundColor Green
            } else {
                Write-Host "✗ Sample test failed with exit code: $LASTEXITCODE" -ForegroundColor Red
            }
        } catch {
            Write-Host "Error running sample test: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "✗ k6 test runner script not found" -ForegroundColor Red
    }
}

# Summary and next steps
Write-Host ""
Write-Host "=== Setup Summary ===" -ForegroundColor Green

if ($k6Available -or $dockerAvailable) {
    Write-Host "✓ k6 runtime available" -ForegroundColor Green
} else {
    Write-Host "✗ No k6 runtime available" -ForegroundColor Red
}

if ($allGood) {
    Write-Host "✓ All required files present" -ForegroundColor Green
} else {
    Write-Host "✗ Missing required files" -ForegroundColor Red
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Ensure your Java application is running" -ForegroundColor White
Write-Host "2. Update k6-tests/configs/*.json with your actual URLs" -ForegroundColor White
Write-Host "3. Customize test scripts for your specific endpoints" -ForegroundColor White
Write-Host "4. Run tests manually: .\k6-tests\run-k6-tests.ps1 -TestType load -Environment dev" -ForegroundColor White
Write-Host "5. Commit changes to trigger Jenkins pipeline with k6 tests" -ForegroundColor White

Write-Host ""
Write-Host "For more information, see k6-tests/README.md" -ForegroundColor Cyan
Write-Host "Setup completed!" -ForegroundColor Green
