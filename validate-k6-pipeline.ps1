#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Validates k6 performance testing integration in Jenkins pipeline
    
.DESCRIPTION
    This script validates that all components for k6 performance testing 
    are properly configured and ready for Jenkins pipeline execution.
    
.EXAMPLE
    .\validate-k6-pipeline.ps1
#>

Write-Host "🔍 Validating k6 Performance Testing Pipeline Integration" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Yellow

$errors = @()
$warnings = @()

# Check 1: Verify k6 test files exist
Write-Host "`n📁 Checking k6 test files..." -ForegroundColor Cyan
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

foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "✅ $file" -ForegroundColor Green
    } else {
        Write-Host "❌ $file" -ForegroundColor Red
        $errors += "Missing file: $file"
    }
}

# Check 2: Verify Jenkinsfile contains k6 stages
Write-Host "`n🔧 Checking Jenkinsfile integration..." -ForegroundColor Cyan
if (Test-Path "Jenkinsfile") {
    $jenkinsContent = Get-Content "Jenkinsfile" -Raw
    
    $requiredSections = @(
        "Performance Testing",
        "runK6Tests",
        "RUN_PERFORMANCE_TESTS",
        "k6-tests/scripts"
    )
    
    foreach ($section in $requiredSections) {
        if ($jenkinsContent -like "*$section*") {
            Write-Host "✅ Found: $section" -ForegroundColor Green
        } else {
            Write-Host "❌ Missing: $section" -ForegroundColor Red
            $errors += "Jenkinsfile missing: $section"
        }
    }
} else {
    Write-Host "❌ Jenkinsfile not found" -ForegroundColor Red
    $errors += "Jenkinsfile not found"
}

# Check 3: Verify k6 runtime availability
Write-Host "`n🚀 Checking k6 runtime..." -ForegroundColor Cyan
try {
    $k6Version = k6 version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ k6 installed: $k6Version" -ForegroundColor Green
    } else {
        Write-Host "⚠️ k6 not found locally" -ForegroundColor Yellow
        $warnings += "k6 not installed locally (will use Docker in pipeline)"
    }
} catch {
    Write-Host "⚠️ k6 not found locally" -ForegroundColor Yellow
    $warnings += "k6 not installed locally (will use Docker in pipeline)"
}

# Check 4: Verify Docker availability
Write-Host "`n🐳 Checking Docker..." -ForegroundColor Cyan
try {
    $dockerVersion = docker --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Docker available: $dockerVersion" -ForegroundColor Green
        
        # Test k6 Docker image
        Write-Host "   Testing k6 Docker image..." -ForegroundColor Gray
        $dockerK6 = docker run --rm grafana/k6:latest version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ k6 Docker image working" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Could not test k6 Docker image" -ForegroundColor Yellow
            $warnings += "k6 Docker image test failed"
        }
    } else {
        Write-Host "❌ Docker not available" -ForegroundColor Red
        $errors += "Docker not available (required for pipeline)"
    }
} catch {
    Write-Host "❌ Docker not available" -ForegroundColor Red
    $errors += "Docker not available (required for pipeline)"
}

# Check 5: Verify directory structure
Write-Host "`n📂 Checking directory structure..." -ForegroundColor Cyan
$requiredDirs = @("k6-tests\scripts", "k6-tests\configs", "k6-tests\results")

foreach ($dir in $requiredDirs) {
    if (Test-Path $dir) {
        Write-Host "✅ $dir" -ForegroundColor Green
    } else {
        Write-Host "❌ $dir" -ForegroundColor Red
        $errors += "Missing directory: $dir"
    }
}

# Check 6: Validate test script syntax (basic)
Write-Host "`n📝 Validating test scripts..." -ForegroundColor Cyan
$testScripts = Get-ChildItem "k6-tests\scripts\*.js" -ErrorAction SilentlyContinue

foreach ($script in $testScripts) {
    $content = Get-Content $script.FullName -Raw
    if ($content -like "*export default function*" -and $content -like "*import*") {
        Write-Host "✅ $($script.Name) - Valid structure" -ForegroundColor Green
    } else {
        Write-Host "⚠️ $($script.Name) - Check syntax" -ForegroundColor Yellow
        $warnings += "Test script $($script.Name) may have syntax issues"
    }
}

# Check 7: PowerShell execution policy
Write-Host "`n🔐 Checking PowerShell execution policy..." -ForegroundColor Cyan
$executionPolicy = Get-ExecutionPolicy
if ($executionPolicy -eq "Restricted") {
    Write-Host "⚠️ PowerShell execution policy is Restricted" -ForegroundColor Yellow
    $warnings += "PowerShell execution policy may block k6 scripts in pipeline"
} else {
    Write-Host "✅ PowerShell execution policy: $executionPolicy" -ForegroundColor Green
}

# Summary
Write-Host "`n" + "=" * 60 -ForegroundColor Yellow
Write-Host "📊 VALIDATION SUMMARY" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Yellow

if ($errors.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "🎉 ALL CHECKS PASSED!" -ForegroundColor Green
    Write-Host "Your k6 performance testing pipeline integration is ready!" -ForegroundColor Green
} elseif ($errors.Count -eq 0) {
    Write-Host "✅ VALIDATION PASSED WITH WARNINGS" -ForegroundColor Yellow
    Write-Host "Warnings found: $($warnings.Count)" -ForegroundColor Yellow
    foreach ($warning in $warnings) {
        Write-Host "  ⚠️ $warning" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ VALIDATION FAILED" -ForegroundColor Red
    Write-Host "Errors found: $($errors.Count)" -ForegroundColor Red
    foreach ($error in $errors) {
        Write-Host "  ❌ $error" -ForegroundColor Red
    }
    Write-Host "`nWarnings found: $($warnings.Count)" -ForegroundColor Yellow
    foreach ($warning in $warnings) {
        Write-Host "  ⚠️ $warning" -ForegroundColor Yellow
    }
}

Write-Host "`n🚀 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Commit and push changes to trigger Jenkins pipeline" -ForegroundColor White
Write-Host "2. Check Jenkins build logs for k6 test execution" -ForegroundColor White
Write-Host "3. Review performance reports in Jenkins artifacts" -ForegroundColor White
Write-Host "4. Adjust thresholds in k6-tests/configs/ as needed" -ForegroundColor White

exit ($errors.Count)
