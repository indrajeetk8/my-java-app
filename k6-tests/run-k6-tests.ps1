#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Run k6 performance tests for the Java application
    
.DESCRIPTION
    This script runs various k6 performance tests against the application.
    It supports different test types (load, stress, spike) and environments.
    
.PARAMETER TestType
    Type of test to run (load, stress, spike, smoke)
    
.PARAMETER Environment
    Target environment (dev, staging, production)
    
.PARAMETER BaseUrl
    Base URL of the application to test
    
.PARAMETER OutputFormat
    Output format for results (json, influxdb, summary)
    
.PARAMETER Monitoring
    Enable monitoring with Grafana and InfluxDB
    
.EXAMPLE
    .\run-k6-tests.ps1 -TestType load -Environment dev
    
.EXAMPLE
    .\run-k6-tests.ps1 -TestType stress -Environment staging -Monitoring
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("load", "stress", "spike", "smoke")]
    [string]$TestType = "load",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("dev", "staging", "production")]
    [string]$Environment = "dev",
    
    [Parameter(Mandatory=$false)]
    [string]$BaseUrl = "",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("json", "influxdb", "summary", "csv")]
    [string]$OutputFormat = "json",
    
    [Parameter(Mandatory=$false)]
    [switch]$Monitoring,
    
    [Parameter(Mandatory=$false)]
    [switch]$Verbose
)

# Configuration
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptPath
$ResultsDir = Join-Path $ScriptPath "results"
$ConfigsDir = Join-Path $ScriptPath "configs"
$ScriptsDir = Join-Path $ScriptPath "scripts"

# Ensure results directory exists
if (!(Test-Path $ResultsDir)) {
    New-Item -ItemType Directory -Path $ResultsDir -Force | Out-Null
}

# Load environment configuration
$ConfigFile = Join-Path $ConfigsDir "$Environment.json"
if (!(Test-Path $ConfigFile)) {
    Write-Error "Configuration file not found: $ConfigFile"
    exit 1
}

$Config = Get-Content $ConfigFile | ConvertFrom-Json

# Set base URL
if ([string]::IsNullOrEmpty($BaseUrl)) {
    $BaseUrl = $Config.baseUrl
}

# Generate timestamp for results
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$ResultFile = Join-Path $ResultsDir "k6-results-$TestType-$Environment-$Timestamp"

Write-Host "=== k6 Performance Test Runner ===" -ForegroundColor Green
Write-Host "Test Type: $TestType" -ForegroundColor Yellow
Write-Host "Environment: $Environment" -ForegroundColor Yellow
Write-Host "Base URL: $BaseUrl" -ForegroundColor Yellow
Write-Host "Output Format: $OutputFormat" -ForegroundColor Yellow
Write-Host ""

# Check if k6 is available
$k6Available = $false
try {
    $k6Version = k6 version 2>$null
    if ($LASTEXITCODE -eq 0) {
        $k6Available = $true
        Write-Host "k6 version: $k6Version" -ForegroundColor Green
    }
} catch {
    Write-Host "k6 not found in PATH, will use Docker" -ForegroundColor Yellow
}

# Build k6 command
$TestScript = Join-Path $ScriptsDir "$TestType-test.js"
if (!(Test-Path $TestScript)) {
    Write-Error "Test script not found: $TestScript"
    exit 1
}

# Prepare environment variables
$env:BASE_URL = $BaseUrl
$env:K6_BASE_URL = $BaseUrl
$env:K6_TEST_TYPE = $TestType
$env:K6_ENVIRONMENT = $Environment

if ($k6Available) {
    # Run k6 directly
    Write-Host "Running k6 test directly..." -ForegroundColor Cyan
    
    $k6Args = @(
        "run",
        "--out", "$OutputFormat=$ResultFile.$OutputFormat"
    )
    
    if ($OutputFormat -eq "influxdb") {
        $k6Args += "--out", "influxdb=http://localhost:8086/k6"
    }
    
    $k6Args += $TestScript
    
    if ($Verbose) {
        Write-Host "k6 command: k6 $($k6Args -join ' ')" -ForegroundColor Gray
    }
    
    & k6 @k6Args
    $exitCode = $LASTEXITCODE
} else {
    # Run k6 with Docker
    Write-Host "Running k6 with Docker..." -ForegroundColor Cyan
    
    $dockerArgs = @(
        "run", "--rm"
        "-v", "$ScriptPath/scripts:/scripts"
        "-v", "$ResultsDir:/results"
        "-e", "BASE_URL=$BaseUrl"
        "grafana/k6:latest"
        "run"
        "--out", "$OutputFormat=/results/k6-results-$TestType-$Environment-$Timestamp.$OutputFormat"
        "/scripts/$TestType-test.js"
    )
    
    if ($Verbose) {
        Write-Host "Docker command: docker $($dockerArgs -join ' ')" -ForegroundColor Gray
    }
    
    & docker @dockerArgs
    $exitCode = $LASTEXITCODE
}

# Process results
Write-Host ""
if ($exitCode -eq 0) {
    Write-Host "=== Test Completed Successfully ===" -ForegroundColor Green
    
    # Display summary if available
    $SummaryFile = "$ResultFile.txt"
    if (Test-Path $SummaryFile) {
        Write-Host ""
        Write-Host "Test Summary:" -ForegroundColor Yellow
        Get-Content $SummaryFile
    }
    
    # Process JSON results if available
    $JsonFile = "$ResultFile.json"
    if (Test-Path $JsonFile) {
        Write-Host ""
        Write-Host "Results saved to: $JsonFile" -ForegroundColor Green
        
        # Parse and display key metrics
        try {
            $Results = Get-Content $JsonFile | ConvertFrom-Json
            # Add custom processing here if needed
            Write-Host "JSON results available for detailed analysis" -ForegroundColor Green
        } catch {
            Write-Host "Could not parse JSON results for summary" -ForegroundColor Yellow
        }
    }
    
} else {
    Write-Host "=== Test Failed ===" -ForegroundColor Red
    Write-Host "Exit code: $exitCode" -ForegroundColor Red
    
    # Check for common issues
    if ($BaseUrl -like "*localhost*") {
        Write-Host ""
        Write-Host "Troubleshooting tips:" -ForegroundColor Yellow
        Write-Host "1. Ensure your application is running on $BaseUrl" -ForegroundColor Yellow
        Write-Host "2. Check if the health endpoint is accessible: $BaseUrl/actuator/health" -ForegroundColor Yellow
        Write-Host "3. Verify firewall/network settings" -ForegroundColor Yellow
    }
}

# Cleanup
Remove-Item Env:BASE_URL -ErrorAction SilentlyContinue
Remove-Item Env:K6_BASE_URL -ErrorAction SilentlyContinue
Remove-Item Env:K6_TEST_TYPE -ErrorAction SilentlyContinue
Remove-Item Env:K6_ENVIRONMENT -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Test execution completed." -ForegroundColor Green
exit $exitCode
