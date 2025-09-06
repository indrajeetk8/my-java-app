Write-Host "=== k6 Setup Verification ===" -ForegroundColor Green
Write-Host ""

# Check if k6 is available
try {
    $k6Version = k6 version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ k6 is installed: $k6Version" -ForegroundColor Green
        $k6Available = $true
    } else {
        $k6Available = $false
    }
} catch {
    $k6Available = $false
}

if (!$k6Available) {
    Write-Host "! k6 not found locally" -ForegroundColor Yellow
}

# Check Docker
try {
    $dockerVersion = docker --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Docker is available: $dockerVersion" -ForegroundColor Green
        $dockerAvailable = $true
    } else {
        $dockerAvailable = $false
    }
} catch {
    $dockerAvailable = $false
}

if (!$dockerAvailable) {
    Write-Host "! Docker not found" -ForegroundColor Yellow
}

# Verify file structure
Write-Host ""
Write-Host "Checking k6 files..." -ForegroundColor Yellow

$files = @(
    "k6-tests\scripts\load-test.js",
    "k6-tests\scripts\stress-test.js", 
    "k6-tests\scripts\spike-test.js",
    "k6-tests\scripts\smoke-test.js",
    "k6-tests\run-k6-tests.ps1"
)

$allFilesPresent = $true
foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "✓ $file" -ForegroundColor Green
    } else {
        Write-Host "✗ $file" -ForegroundColor Red
        $allFilesPresent = $false
    }
}

Write-Host ""
if ($k6Available -or $dockerAvailable) {
    Write-Host "✓ Ready to run k6 tests!" -ForegroundColor Green
} else {
    Write-Host "! No k6 runtime available. Install k6 or ensure Docker is running." -ForegroundColor Yellow
}

if ($allFilesPresent) {
    Write-Host "✓ All k6 test files are present!" -ForegroundColor Green
} else {
    Write-Host "✗ Some k6 files are missing!" -ForegroundColor Red
}
