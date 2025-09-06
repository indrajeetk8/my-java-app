# 🚀 Quick Jenkins Access Guide

Your Jenkins server is now running! Follow these steps to access and set up your CI/CD pipeline.

## 📋 Server Information

- **Jenkins URL**: http://localhost:8080
- **Initial Admin Password**: `4a7177bcebf1478cb01eb6f2d9da419e`
- **Container Name**: jenkins-server

## 🔧 Step-by-Step Setup

### Step 1: Access Jenkins Web Interface

1. Open your web browser
2. Go to: **http://localhost:8080**
3. You should see the "Unlock Jenkins" page

### Step 2: Initial Setup

1. **Enter Admin Password**: `4a7177bcebf1478cb01eb6f2d9da419e`
2. **Install Suggested Plugins** (recommended)
   - This will install essential plugins automatically
   - Wait for the installation to complete (2-5 minutes)

### Step 3: Create Admin User

1. **Create First Admin User**:
   ```
   Username: admin
   Password: [choose a secure password]
   Full Name: Administrator
   Email: your-email@domain.com
   ```
2. Click **Save and Continue**

### Step 4: Instance Configuration

1. **Jenkins URL**: Keep default `http://localhost:8080/`
2. Click **Save and Finish**
3. Click **Start using Jenkins**

## 🔨 Setting Up Your Pipeline

### Step 5: Install Required Plugins

1. Go to **Manage Jenkins** → **Manage Plugins**
2. Click **Available** tab
3. Search and install these plugins:
   ```
   - Pipeline
   - Git Plugin
   - Docker Pipeline
   - Maven Integration
   - Blue Ocean (for better UI)
   - Workspace Cleanup
   ```

### Step 6: Configure Global Tools

1. Go to **Manage Jenkins** → **Global Tool Configuration**

2. **Maven Configuration**:
   - Click **Add Maven**
   - Name: `Maven-3.8.6`
   - Check **Install automatically**
   - Version: `3.8.6`

3. **JDK Configuration**:
   - Click **Add JDK**
   - Name: `JDK-11`
   - Check **Install automatically**
   - Installer: **Extract *.zip/*.tar.gz**
   - Version: Choose OpenJDK 11

4. **Docker Configuration**:
   - Click **Add Docker**
   - Name: `docker`
   - Check **Install automatically**

### Step 7: Create Your Pipeline Job

1. **New Item** → Enter name: `my-java-app-pipeline`
2. Select **Pipeline** → Click **OK**

3. **Pipeline Configuration**:
   ```
   Definition: Pipeline script from SCM
   SCM: Git
   Repository URL: file:///workspace (since we mounted your project)
   Branch Specifier: */main
   Script Path: Jenkinsfile
   ```

4. Click **Save**

### Step 8: Set Up Credentials (Optional)

If you need Nexus or Docker registry credentials:

1. Go to **Manage Jenkins** → **Manage Credentials**
2. Click **System** → **Global credentials**
3. Click **Add Credentials**

**For Nexus**:
```
Kind: Username with password
ID: nexus-credentials
Username: admin
Password: [your-nexus-password]
```

## 🎯 Running Your Pipeline

### Option 1: Manual Build
1. Go to your pipeline job
2. Click **Build Now**
3. Watch the build progress in the **Build History**

### Option 2: Blue Ocean Interface (Recommended)
1. Click **Open Blue Ocean** in the left sidebar
2. Select your pipeline
3. Click **Run** to start a build
4. View the visual pipeline execution

## 📊 Viewing Pipeline Results

### Build Console Output
1. Click on a build number (e.g., #1, #2)
2. Click **Console Output** to see detailed logs

### Blue Ocean Pipeline View
1. In Blue Ocean, click on any running/completed build
2. See visual representation of pipeline stages
3. Click on individual stages to see details

### Build Artifacts
1. In the build page, scroll down to see **Build Artifacts**
2. Download JAR files or other generated artifacts

## 🔍 Monitoring Your Application

After successful deployment, you can monitor:

- **Application URL**: http://localhost:8080 (if deployed locally)
- **Health Check**: http://localhost:8080/actuator/health
- **Metrics**: http://localhost:8080/actuator/metrics

## 🛠️ Useful Commands

### Jenkins Container Management
```powershell
# Check Jenkins logs
docker logs jenkins-server

# Stop Jenkins
docker-compose -f jenkins-docker-compose.yml stop

# Start Jenkins
docker-compose -f jenkins-docker-compose.yml start

# Restart Jenkins
docker-compose -f jenkins-docker-compose.yml restart

# Access Jenkins container shell
docker exec -it jenkins-server bash
```

### Application Monitoring
```powershell
# Check if your app is running (after deployment)
docker ps | findstr my-java-app

# View application logs
docker logs my-java-app-dev

# Check application health
curl http://localhost:8080/actuator/health
```

## 🎨 Enhanced UI with Blue Ocean

Blue Ocean provides a modern, visual interface for Jenkins:

1. **Install Blue Ocean Plugin** (if not already installed)
2. Click **Open Blue Ocean** in Jenkins sidebar
3. Enjoy the modern pipeline visualization!

Features:
- Visual pipeline editor
- Real-time build progress
- Better error visualization
- Branch-based pipeline views

## 🚨 Troubleshooting

### Jenkins Won't Start
```powershell
# Check if port 8080 is already in use
netstat -an | findstr :8080

# Check Jenkins container logs
docker logs jenkins-server

# Restart Jenkins
docker-compose -f jenkins-docker-compose.yml restart
```

### Pipeline Fails
1. **Check Console Output** for error details
2. **Verify Jenkinsfile** syntax
3. **Check tool configurations** (Maven, JDK, Docker)
4. **Review credentials** if using external services

### Build Fails
1. **Maven Issues**: Check if Maven is properly configured
2. **Java Issues**: Verify JDK installation
3. **Docker Issues**: Ensure Docker is running and accessible

## 🔒 Security Notes

- Change the admin password regularly
- Use Jenkins credentials store for secrets
- Enable security features in production
- Regular Jenkins and plugin updates

---

## 🎯 Next Steps

1. **Access Jenkins**: http://localhost:8080
2. **Complete setup** using the password above
3. **Create your pipeline** following the steps
4. **Run your first build**
5. **Monitor and iterate**

Your CI/CD pipeline is ready to go! 🚀
