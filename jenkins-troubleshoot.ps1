#!/usr/bin/env pwsh
# Jenkins Build Troubleshooting Script

Write-Host "=== Jenkins Build Environment Check ===" -ForegroundColor Green

# Check Java
Write-Host "`n1. Checking Java..." -ForegroundColor Yellow
try {
    $javaVersion = & java -version 2>&1
    Write-Host "Java found: $($javaVersion[0])" -ForegroundColor Green
} catch {
    Write-Host "❌ Java not found in PATH" -ForegroundColor Red
    Write-Host "Add Java to system PATH or configure JAVA_HOME" -ForegroundColor Yellow
}

# Check Maven
Write-Host "`n2. Checking Maven..." -ForegroundColor Yellow
try {
    $mvnVersion = & mvn -version 2>&1 | Select-Object -First 1
    Write-Host "Maven found: $mvnVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Maven not found in PATH" -ForegroundColor Red
}

# Check Git
Write-Host "`n3. Checking Git..." -ForegroundColor Yellow
try {
    $gitVersion = & git --version 2>&1
    Write-Host "Git found: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Git not found in PATH" -ForegroundColor Red
}

# Check Project Structure
Write-Host "`n4. Checking Project Structure..." -ForegroundColor Yellow
$requiredFiles = @("pom.xml", "Jenkinsfile", "src/main/java", "src/test/java")
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "✅ $file exists" -ForegroundColor Green
    } else {
        Write-Host "❌ $file missing" -ForegroundColor Red
    }
}

# Test Maven Build
Write-Host "`n5. Testing Maven Build..." -ForegroundColor Yellow
try {
    Write-Host "Running 'mvn clean compile'..." -ForegroundColor Cyan
    $buildResult = & mvn clean compile 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Maven build successful" -ForegroundColor Green
    } else {
        Write-Host "❌ Maven build failed" -ForegroundColor Red
        Write-Host "Last few lines of build output:" -ForegroundColor Yellow
        $buildResult | Select-Object -Last 10 | Write-Host
    }
} catch {
    Write-Host "❌ Maven build command failed" -ForegroundColor Red
}

# Test Maven Test
Write-Host "`n6. Testing Maven Tests..." -ForegroundColor Yellow
try {
    Write-Host "Running 'mvn test'..." -ForegroundColor Cyan
    $testResult = & mvn test 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Maven tests successful" -ForegroundColor Green
    } else {
        Write-Host "❌ Maven tests failed" -ForegroundColor Red
        Write-Host "Check target/surefire-reports/ for details" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Maven test command failed" -ForegroundColor Red
}

# Check Environment Variables
Write-Host "`n7. Checking Environment Variables..." -ForegroundColor Yellow
$envVars = @("JAVA_HOME", "MAVEN_HOME", "PATH")
foreach ($var in $envVars) {
    $value = [Environment]::GetEnvironmentVariable($var)
    if ($value) {
        Write-Host "✅ $var = $($value.Substring(0, [Math]::Min(50, $value.Length)))..." -ForegroundColor Green
    } else {
        Write-Host "⚠️  $var not set" -ForegroundColor Yellow
    }
}

Write-Host "`n=== Troubleshooting Complete ===" -ForegroundColor Green
Write-Host "If issues persist, check Jenkins console logs and tool configuration." -ForegroundColor Cyan
