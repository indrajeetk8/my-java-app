@echo off
echo ================================================
echo    Setting up Jenkins for Your Java App
echo ================================================

echo.
echo 🚀 Step 1: Starting Jenkins Server...
docker-compose -f jenkins-docker-compose.yml up -d jenkins

echo.
echo ⏱️  Waiting for Jenkins to start (30 seconds)...
timeout /t 30 /nobreak >nul

echo.
echo 🔑 Step 2: Getting Jenkins Admin Password...
echo.
echo Your Jenkins admin password is:
echo ===============================================
docker exec jenkins-server cat /var/jenkins_home/secrets/initialAdminPassword
echo ===============================================
echo.

echo 📊 Step 3: Jenkins Server Information
echo.
echo 🌐 Jenkins URL: http://localhost:8080
echo 🐳 Container: jenkins-server
echo 📁 Project mounted at: /workspace
echo.

echo 📋 Step 4: Next Steps
echo.
echo 1. Open your browser and go to: http://localhost:8080
echo 2. Use the admin password shown above
echo 3. Follow the setup wizard and install suggested plugins
echo 4. Create your admin user
echo 5. Follow the QUICK_JENKINS_ACCESS.md guide for pipeline setup
echo.

echo ⚡ Quick Commands:
echo - View Jenkins logs: docker logs jenkins-server
echo - Stop Jenkins: docker-compose -f jenkins-docker-compose.yml stop
echo - Restart Jenkins: docker-compose -f jenkins-docker-compose.yml restart
echo.

echo 📖 For detailed setup instructions, see:
echo - QUICK_JENKINS_ACCESS.md
echo - JENKINS_SETUP.md
echo.

pause
