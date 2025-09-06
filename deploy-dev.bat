@echo off
REM Development Environment Deployment Script
REM This script deploys the application to the development environment

echo ================================================
echo        Development Environment Deployment
echo ================================================

REM Set environment variables
set APP_NAME=my-java-app
set ENVIRONMENT=development
set IMAGE_TAG=%1
set CONTAINER_NAME=%APP_NAME%-dev
set HOST_PORT=8080
set CONTAINER_PORT=8080

REM Default to latest if no tag provided
if "%IMAGE_TAG%"=="" set IMAGE_TAG=latest

echo Deploying %APP_NAME%:%IMAGE_TAG% to %ENVIRONMENT% environment...

REM Stop and remove existing container
echo Stopping existing container...
docker stop %CONTAINER_NAME% 2>nul
docker rm %CONTAINER_NAME% 2>nul

REM Pull latest image if using remote registry
REM docker pull %APP_NAME%:%IMAGE_TAG%

REM Start new container
echo Starting new container...
docker run -d ^
  --name %CONTAINER_NAME% ^
  -p %HOST_PORT%:%CONTAINER_PORT% ^
  -e SPRING_PROFILES_ACTIVE=dev ^
  -e JAVA_OPTS="-Xmx512m -Xms256m" ^
  -v "%cd%\logs:/app/logs" ^
  --restart unless-stopped ^
  %APP_NAME%:%IMAGE_TAG%

REM Check if container started successfully
timeout /t 5 /nobreak >nul
docker ps | findstr %CONTAINER_NAME% >nul
if %errorlevel% equ 0 (
    echo ✅ Container started successfully!
    echo Application URL: http://localhost:%HOST_PORT%
    echo Health Check: http://localhost:%HOST_PORT%/actuator/health
    
    REM Wait for application to start
    echo Waiting for application to start...
    timeout /t 10 /nobreak >nul
    
    REM Health check
    echo Performing health check...
    powershell -Command "try { $response = Invoke-RestMethod -Uri 'http://localhost:%HOST_PORT%/actuator/health' -TimeoutSec 10; if ($response.status -eq 'UP') { Write-Host '✅ Health check passed!' -ForegroundColor Green } else { Write-Host '❌ Health check failed!' -ForegroundColor Red } } catch { Write-Host '❌ Health check failed - application not ready!' -ForegroundColor Red }"
) else (
    echo ❌ Container failed to start!
    echo Container logs:
    docker logs %CONTAINER_NAME%
    exit /b 1
)

echo.
echo Deployment Summary:
echo - Environment: %ENVIRONMENT%
echo - Container: %CONTAINER_NAME%
echo - Image: %APP_NAME%:%IMAGE_TAG%
echo - Port: %HOST_PORT%
echo - Profile: dev
echo.
echo Use 'docker logs %CONTAINER_NAME%' to view application logs
echo Use 'docker stop %CONTAINER_NAME%' to stop the application

echo ================================================
echo        Development Deployment Complete!
echo ================================================
