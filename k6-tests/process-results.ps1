#!/usr/bin/env pwsh

param(
    [Parameter(Mandatory=$true)]
    [string]$ResultsPath,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "./reports",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("junit", "html", "json")]
    [string]$Format = "junit"
)

# Ensure output directory exists
if (!(Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

Write-Host "=== k6 Results Processor ===" -ForegroundColor Green
Write-Host "Results Path: $ResultsPath" -ForegroundColor Yellow
Write-Host "Output Path: $OutputPath" -ForegroundColor Yellow
Write-Host "Format: $Format" -ForegroundColor Yellow
Write-Host ""

# Find the latest results file
$JsonFiles = Get-ChildItem -Path $ResultsPath -Filter "*.json" | Sort-Object LastWriteTime -Descending
if ($JsonFiles.Count -eq 0) {
    Write-Error "No JSON result files found in $ResultsPath"
    exit 1
}

$LatestResults = $JsonFiles[0]
Write-Host "Processing: $($LatestResults.Name)" -ForegroundColor Cyan

try {
    # Read and parse the results
    $ResultsContent = Get-Content $LatestResults.FullName -Raw
    $Results = $ResultsContent | ConvertFrom-Json
    
    # Initialize test results
    $TestResults = @{
        TotalRequests = 0
        FailedRequests = 0
        SuccessRate = 0
        AverageResponseTime = 0
        P95ResponseTime = 0
        P99ResponseTime = 0
        MaxResponseTime = 0
        TestDuration = 0
        VirtualUsers = 0
        Checks = @{
            Total = 0
            Passed = 0
            Failed = 0
        }
    }
    
    # Process each result line (simplified processing)
    foreach ($line in $Results) {
        if ($line.type -eq "Point" -and $line.data) {
            $metricName = $line.metric
            $value = [double]$line.data.value
            
            switch ($metricName) {
                "http_reqs" { $TestResults.TotalRequests += $value }
                "http_req_failed" { $TestResults.FailedRequests += $value }
                "checks" { 
                    $TestResults.Checks.Total += 1
                    if ($value -eq 1) {
                        $TestResults.Checks.Passed += 1
                    } else {
                        $TestResults.Checks.Failed += 1
                    }
                }
            }
        }
        
        # Extract summary metrics if available
        if ($line.type -eq "Metric" -and $line.data -and $line.data.type -eq "trend" -and $line.metric -eq "http_req_duration") {
            if ($line.data.values) {
                $TestResults.AverageResponseTime = [double]$line.data.values.avg
                $TestResults.P95ResponseTime = [double]$line.data.values."p(95)"
                $TestResults.P99ResponseTime = [double]$line.data.values."p(99)"
                $TestResults.MaxResponseTime = [double]$line.data.values.max
            }
        }
    }
    
    # Calculate success rate
    if ($TestResults.TotalRequests -gt 0) {
        $TestResults.SuccessRate = [math]::Round(((($TestResults.TotalRequests - $TestResults.FailedRequests) / $TestResults.TotalRequests) * 100), 2)
    }
    
    # Generate timestamp
    $Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    
    # Display results
    Write-Host "Test Results Summary:" -ForegroundColor Yellow
    Write-Host "Total Requests: $($TestResults.TotalRequests)" -ForegroundColor White
    Write-Host "Failed Requests: $($TestResults.FailedRequests)" -ForegroundColor White
    Write-Host "Success Rate: $($TestResults.SuccessRate)%" -ForegroundColor White
    Write-Host "Average Response Time: $([math]::Round($TestResults.AverageResponseTime, 2))ms" -ForegroundColor White
    Write-Host "P95 Response Time: $([math]::Round($TestResults.P95ResponseTime, 2))ms" -ForegroundColor White
    Write-Host "Checks Passed: $($TestResults.Checks.Passed)/$($TestResults.Checks.Total)" -ForegroundColor White
    Write-Host ""
    
    # Generate JUnit XML report
    if ($Format -eq "junit") {
        $TestsPassed = ($TestResults.SuccessRate -ge 95 -and $TestResults.AverageResponseTime -le 1000 -and $TestResults.Checks.Failed -eq 0)
        
        $xml = @"
<?xml version="1.0" encoding="UTF-8"?>
<testsuite name="k6-performance-tests" tests="4" failures="$(if ($TestsPassed) { 0 } else { 1 })" time="$([math]::Round($TestResults.TestDuration, 2))" timestamp="$Timestamp">
    <testcase classname="k6.performance" name="Success Rate" time="0">
        $(if ($TestResults.SuccessRate -lt 95) { "<failure message=`"Success rate below 95%: $($TestResults.SuccessRate)%`" type=`"AssertionFailure`"></failure>" })
    </testcase>
    <testcase classname="k6.performance" name="Average Response Time" time="$([math]::Round($TestResults.AverageResponseTime/1000, 3))">
        $(if ($TestResults.AverageResponseTime -gt 1000) { "<failure message=`"Average response time above 1000ms: $([math]::Round($TestResults.AverageResponseTime, 2))ms`" type=`"AssertionFailure`"></failure>" })
    </testcase>
    <testcase classname="k6.performance" name="HTTP Requests" time="0">
        $(if ($TestResults.FailedRequests -gt ($TestResults.TotalRequests * 0.05)) { "<failure message=`"Too many failed requests: $($TestResults.FailedRequests)/$($TestResults.TotalRequests)`" type=`"AssertionFailure`"></failure>" })
    </testcase>
    <testcase classname="k6.performance" name="Checks" time="0">
        $(if ($TestResults.Checks.Failed -gt 0) { "<failure message=`"$($TestResults.Checks.Failed) checks failed out of $($TestResults.Checks.Total)`" type=`"AssertionFailure`"></failure>" })
    </testcase>
    <system-out>
Total Requests: $($TestResults.TotalRequests)
Failed Requests: $($TestResults.FailedRequests)
Success Rate: $($TestResults.SuccessRate)%
Average Response Time: $([math]::Round($TestResults.AverageResponseTime, 2))ms
P95 Response Time: $([math]::Round($TestResults.P95ResponseTime, 2))ms
Checks: $($TestResults.Checks.Passed)/$($TestResults.Checks.Total) passed
    </system-out>
</testsuite>
"@
        
        $JUnitPath = Join-Path $OutputPath "k6-results.xml"
        $xml | Out-File -FilePath $JUnitPath -Encoding UTF8
        Write-Host "JUnit report saved: $JUnitPath" -ForegroundColor Green
    }
    
    # Generate JSON report
    if ($Format -eq "json") {
        $JsonReport = $TestResults | ConvertTo-Json -Depth 3
        $JsonPath = Join-Path $OutputPath "k6-summary.json"
        $JsonReport | Out-File -FilePath $JsonPath -Encoding UTF8
        Write-Host "JSON report saved: $JsonPath" -ForegroundColor Green
    }
    
    # Determine if tests passed
    $TestsPassed = $true
    $FailureReasons = @()
    
    if ($TestResults.SuccessRate -lt 95) {
        $TestsPassed = $false
        $FailureReasons += "Success rate below 95% ($($TestResults.SuccessRate)%)"
    }
    
    if ($TestResults.AverageResponseTime -gt 1000) {
        $TestsPassed = $false
        $FailureReasons += "Average response time above 1000ms ($([math]::Round($TestResults.AverageResponseTime, 2))ms)"
    }
    
    if ($TestResults.Checks.Failed -gt 0) {
        $TestsPassed = $false
        $FailureReasons += "$($TestResults.Checks.Failed) checks failed"
    }
    
    if ($TestsPassed) {
        Write-Host "=== Performance Tests PASSED ===" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "=== Performance Tests FAILED ===" -ForegroundColor Red
        Write-Host "Failure Reasons:" -ForegroundColor Red
        $FailureReasons | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
        exit 1
    }
    
} catch {
    Write-Error "Error processing results: $($_.Exception.Message)"
    exit 1
}
