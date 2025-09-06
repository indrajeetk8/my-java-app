@echo off
REM Production Environment Deployment Script
REM This script deploys the application to the production environment with safety checks

echo ================================================
echo        Production Environment Deployment
echo ================================================

REM Set environment variables
set APP_NAME=my-java-app
set ENVIRONMENT=production
set IMAGE_TAG=%1
set CONTAINER_NAME=%APP_NAME%-prod
set BACKUP_CONTAINER=%APP_NAME%-prod-backup
set HOST_PORT=8080
set CONTAINER_PORT=8080
set HEALTH_ENDPOINT=http://localhost:%HOST_PORT%/actuator/health

REM Validation checks
if "%IMAGE_TAG%"=="" (
    echo ❌ Error: Image tag is required for production deployment!
    echo Usage: deploy-prod.bat ^<image-tag^>
    echo Example: deploy-prod.bat 2.0.0-abc123
    exit /b 1
)

echo.
echo ⚠️  WARNING: This will deploy to PRODUCTION environment!
echo Image: %APP_NAME%:%IMAGE_TAG%
echo Container: %CONTAINER_NAME%
echo.
set /p CONFIRM="Are you sure you want to continue? (y/N): "
if /i not "%CONFIRM%"=="y" (
    echo Deployment cancelled.
    exit /b 0
)

echo.
echo Starting production deployment...

REM Check if Docker is running
docker version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Error: Docker is not running!
    exit /b 1
)

REM Check if image exists locally or pull from registry
echo Checking image availability...
docker image inspect %APP_NAME%:%IMAGE_TAG% >nul 2>&1
if %errorlevel% neq 0 (
    echo Image not found locally, attempting to pull from registry...
    docker pull %APP_NAME%:%IMAGE_TAG%
    if %errorlevel% neq 0 (
        echo ❌ Error: Failed to pull image %APP_NAME%:%IMAGE_TAG%
        exit /b 1
    )
)

REM Create backup of current container (if exists)
docker ps | findstr %CONTAINER_NAME% >nul
if %errorlevel% equ 0 (
    echo Creating backup of current production container...
    docker stop %BACKUP_CONTAINER% 2>nul
    docker rm %BACKUP_CONTAINER% 2>nul
    docker rename %CONTAINER_NAME% %BACKUP_CONTAINER%
    echo ✅ Backup created as %BACKUP_CONTAINER%
)

REM Deploy new version
echo Deploying new version...
docker run -d ^
  --name %CONTAINER_NAME% ^
  -p %HOST_PORT%:%CONTAINER_PORT% ^
  -e SPRING_PROFILES_ACTIVE=prod ^
  -e JAVA_OPTS="-Xmx1g -Xms512m -XX:+UseG1GC -XX:MaxGCPauseMillis=200" ^
  -v "%cd%\logs:/app/logs" ^
  -v "%cd%\config:/app/config" ^
  --restart unless-stopped ^
  --memory=1.5g ^
  --cpus=1.0 ^
  %APP_NAME%:%IMAGE_TAG%

if %errorlevel% neq 0 (
    echo ❌ Error: Failed to start new container!
    goto ROLLBACK
)

REM Wait for application to start
echo Waiting for application to start (30 seconds)...
timeout /t 30 /nobreak >nul

REM Comprehensive health checks
echo Performing health checks...
set HEALTH_CHECK_PASSED=false

REM Basic container check
docker ps | findstr %CONTAINER_NAME% >nul
if %errorlevel% neq 0 (
    echo ❌ Container health check failed - container not running!
    goto ROLLBACK
)

REM Application health check
powershell -Command "try { $response = Invoke-RestMethod -Uri '%HEALTH_ENDPOINT%' -TimeoutSec 30; if ($response.status -eq 'UP') { exit 0 } else { exit 1 } } catch { exit 1 }"
if %errorlevel% equ 0 (
    set HEALTH_CHECK_PASSED=true
    echo ✅ Application health check passed!
) else (
    echo ❌ Application health check failed!
    goto ROLLBACK
)

REM Smoke tests
echo Running smoke tests...
powershell -Command "try { $response = Invoke-RestMethod -Uri 'http://localhost:%HOST_PORT%/' -TimeoutSec 10; if ($response -and $response.Length -gt 0) { exit 0 } else { exit 1 } } catch { exit 1 }"
if %errorlevel% neq 0 (
    echo ❌ Smoke test failed!
    goto ROLLBACK
)

REM Success - cleanup backup
if "%HEALTH_CHECK_PASSED%"=="true" (
    echo ✅ Deployment successful! Cleaning up backup...
    docker stop %BACKUP_CONTAINER% 2>nul
    docker rm %BACKUP_CONTAINER% 2>nul
    
    echo.
    echo 🎉 Production deployment completed successfully!
    echo.
    echo Deployment Summary:
    echo - Environment: %ENVIRONMENT%
    echo - Container: %CONTAINER_NAME%
    echo - Image: %APP_NAME%:%IMAGE_TAG%
    echo - Port: %HOST_PORT%
    echo - URL: http://localhost:%HOST_PORT%
    echo - Health: %HEALTH_ENDPOINT%
    echo.
    echo Monitoring commands:
    echo - View logs: docker logs -f %CONTAINER_NAME%
    echo - Container stats: docker stats %CONTAINER_NAME%
    echo - Stop application: docker stop %CONTAINER_NAME%
    
    goto END
)

:ROLLBACK
echo.
echo ⚠️  INITIATING ROLLBACK PROCEDURE...
echo.

REM Stop failed deployment
docker stop %CONTAINER_NAME% 2>nul
docker rm %CONTAINER_NAME% 2>nul

REM Check if backup exists to restore
docker ps -a | findstr %BACKUP_CONTAINER% >nul
if %errorlevel% equ 0 (
    echo Restoring from backup...
    docker rename %BACKUP_CONTAINER% %CONTAINER_NAME%
    docker start %CONTAINER_NAME%
    
    REM Wait and check if rollback was successful
    timeout /t 15 /nobreak >nul
    powershell -Command "try { $response = Invoke-RestMethod -Uri '%HEALTH_ENDPOINT%' -TimeoutSec 15; if ($response.status -eq 'UP') { exit 0 } else { exit 1 } } catch { exit 1 }"
    if %errorlevel% equ 0 (
        echo ✅ Rollback successful - previous version restored!
    ) else (
        echo ❌ Rollback failed - manual intervention required!
        echo Container logs:
        docker logs %CONTAINER_NAME%
    )
) else (
    echo ❌ No backup available for rollback!
    echo Manual intervention required!
)

echo.
echo ❌ Production deployment failed!
exit /b 1

:END
echo ================================================
echo        Production Deployment Complete!
echo ================================================
