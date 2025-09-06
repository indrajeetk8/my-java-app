# Jenkins CI/CD Pipeline Setup Guide

This guide will help you set up Jenkins for your Spring Boot application CI/CD pipeline.

## 📋 Prerequisites

- Jenkins 2.400+ installed and running
- Docker installed on Jenkins agents
- Maven 3.8+ 
- Java 11+
- Git access to your repository

## 🛠️ Jenkins Configuration

### 1. Install Required Plugins

Go to **Manage Jenkins** → **Manage Plugins** and install:

#### Essential Plugins:
- **Pipeline** (Pipeline Suite)
- **Git Plugin**
- **Maven Integration Plugin**
- **Docker Pipeline Plugin**
- **Credentials Plugin**
- **Workspace Cleanup Plugin**

#### Optional but Recommended:
- **Blue Ocean** (Modern Pipeline UI)
- **SonarQube Scanner**
- **Slack Notification**
- **Email Extension**
- **Prometheus Metrics**
- **Build Timeout**
- **Timestamper**

### 2. Configure Global Tools

Navigate to **Manage Jenkins** → **Global Tool Configuration**:

#### Maven Configuration:
```
Name: Maven-3.8.6
Install automatically: ✓
Version: 3.8.6
```

#### JDK Configuration:
```
Name: JDK-11
Install automatically: ✓ (from adoptium.net)
Version: jdk-11.0.19+7
```

#### Docker Configuration:
```
Name: docker
Install automatically: ✓
Version: latest
```

### 3. Set Up Credentials

Go to **Manage Jenkins** → **Manage Credentials** → **System** → **Global credentials**:

#### Nexus Repository Credentials:
```
Kind: Username with password
ID: nexus-credentials
Username: [your-nexus-username]
Password: [your-nexus-password]
Description: Nexus Repository Credentials
```

#### Docker Registry Credentials:
```
Kind: Username with password
ID: docker-registry-credentials
Username: [your-docker-username]
Password: [your-docker-password]
Description: Docker Registry Credentials
```

#### Git Credentials (if private repo):
```
Kind: SSH Username with private key
ID: git-credentials
Username: git
Private Key: [your-private-key]
Description: Git Repository Access
```

### 4. Create Pipeline Job

1. **New Item** → **Pipeline**
2. **Pipeline** → **Definition** → **Pipeline script from SCM**
3. **SCM** → **Git**
4. **Repository URL**: `https://github.com/your-username/my-java-app.git`
5. **Credentials**: Select your Git credentials
6. **Branch Specifier**: `*/main` (or your default branch)
7. **Script Path**: `Jenkinsfile`

### 5. Configure Pipeline Parameters

In your Pipeline job configuration, enable:
- **This project is parameterized**
- Add parameters as defined in the Jenkinsfile

## 🐳 Docker Setup for Jenkins

### Jenkins with Docker Support

If running Jenkins in Docker, use this docker-compose:

```yaml
version: '3.8'
services:
  jenkins:
    image: jenkins/jenkins:lts
    container_name: jenkins
    ports:
      - "8080:8080"
      - "50000:50000"
    volumes:
      - jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
      - ./jenkins/casc.yaml:/var/jenkins_home/casc_configs/jenkins.yaml
    environment:
      - CASC_JENKINS_CONFIG=/var/jenkins_home/casc_configs
    restart: unless-stopped

volumes:
  jenkins_home:
```

### Jenkins Agent with Docker

For dedicated build agents:

```dockerfile
FROM jenkins/inbound-agent:latest

USER root

# Install Docker
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    maven \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce-cli

# Install Trivy for security scanning
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

USER jenkins
```

## 🔧 Pipeline Configuration Files

### Environment-Specific Properties

Create these files in your project:

#### `application-dev.properties`
```properties
spring.profiles.active=dev
server.port=8080
spring.datasource.url=jdbc:h2:mem:devdb
spring.jpa.hibernate.ddl-auto=create-drop
logging.level.com.example=DEBUG
```

#### `application-staging.properties`
```properties
spring.profiles.active=staging
server.port=8080
spring.datasource.url=jdbc:postgresql://postgres-staging:5432/myapp_staging
spring.datasource.username=${DB_USER}
spring.datasource.password=${DB_PASSWORD}
spring.jpa.hibernate.ddl-auto=validate
logging.level.com.example=INFO
```

#### `application-prod.properties`
```properties
spring.profiles.active=prod
server.port=8080
spring.datasource.url=${DATABASE_URL}
spring.datasource.username=${DB_USER}
spring.datasource.password=${DB_PASSWORD}
spring.jpa.hibernate.ddl-auto=validate
logging.level.com.example=WARN
management.endpoints.web.exposure.include=health,info,metrics
```

## 🚀 Deployment Strategies

### 1. Simple Docker Deployment
```bash
# Stop existing container
docker stop my-java-app || true
docker rm my-java-app || true

# Run new version
docker run -d \
  --name my-java-app \
  -p 8080:8080 \
  -e SPRING_PROFILES_ACTIVE=prod \
  my-java-app:${BUILD_NUMBER}
```

### 2. Blue-Green Deployment
```bash
# Start new version (green)
docker run -d \
  --name my-java-app-green \
  -p 8081:8080 \
  my-java-app:${BUILD_NUMBER}

# Health check
curl -f http://localhost:8081/actuator/health

# Switch traffic (update load balancer)
# Stop old version (blue)
docker stop my-java-app-blue
docker rm my-java-app-blue

# Rename containers
docker rename my-java-app-green my-java-app-blue
```

### 3. Kubernetes Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-java-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-java-app
  template:
    metadata:
      labels:
        app: my-java-app
    spec:
      containers:
      - name: my-java-app
        image: my-java-app:${BUILD_NUMBER}
        ports:
        - containerPort: 8080
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "prod"
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
```

## 📊 Monitoring and Notifications

### Slack Integration

1. Install **Slack Notification Plugin**
2. Configure in **Manage Jenkins** → **Configure System** → **Slack**
3. Add Slack token to credentials
4. Update Jenkinsfile notification function

### Email Notifications

1. Configure SMTP in **Manage Jenkins** → **Configure System** → **E-mail Notification**
2. Install **Email Extension Plugin**
3. Configure default recipients

### Prometheus Metrics

Add to your application:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>
```

## 🔒 Security Best Practices

### 1. Jenkins Security
- Enable **CSRF Protection**
- Use **Matrix-based security**
- Regular **security updates**
- **Audit logs** enabled

### 2. Credentials Management
- Never hardcode secrets
- Use Jenkins Credentials Store
- Rotate credentials regularly
- Use least privilege principle

### 3. Pipeline Security
- **Code review** for Jenkinsfile changes
- **Signed commits** for production deployments
- **Static code analysis** in pipeline
- **Container image scanning**

## 🐛 Troubleshooting

### Common Issues

#### 1. Maven Build Failures
```bash
# Debug Maven build
mvn clean compile -X

# Check Java version
java -version
mvn -version
```

#### 2. Docker Build Issues
```bash
# Check Docker daemon
docker info

# Build with verbose output
docker build --no-cache --progress=plain .
```

#### 3. Pipeline Failures
- Check Jenkins logs: `${JENKINS_HOME}/jobs/${JOB_NAME}/builds/${BUILD_NUMBER}/log`
- Verify credentials and permissions
- Check agent connectivity

#### 4. Deployment Issues
```bash
# Check application logs
docker logs my-java-app

# Check health endpoint
curl http://localhost:8080/actuator/health

# Check database connectivity
docker exec -it postgres-prod psql -U username -d database
```

## 📈 Performance Optimization

### Jenkins Performance
- **Increase heap size**: `-Xmx2g`
- **Use SSD storage** for Jenkins home
- **Clean old builds** regularly
- **Use pipeline caching**

### Build Performance
- **Parallel stages** where possible
- **Maven dependency caching**
- **Multi-stage Docker builds**
- **Build only changed modules**

## 🔄 Backup and Disaster Recovery

### Jenkins Backup
```bash
# Backup Jenkins home
tar -czf jenkins-backup-$(date +%Y%m%d).tar.gz $JENKINS_HOME

# Database backup
pg_dump myapp_prod > backup-$(date +%Y%m%d).sql
```

### Recovery Procedures
1. **Jenkins Configuration**: Restore from backup
2. **Rebuild Pipeline**: From source control
3. **Database Recovery**: From latest backup
4. **Credential Recreation**: From secure store

## 📚 Additional Resources

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Docker Pipeline Plugin](https://plugins.jenkins.io/docker-workflow/)
- [Blue Ocean](https://www.jenkins.io/projects/blueocean/)

## 🎯 Next Steps

1. **Set up monitoring** with Prometheus/Grafana
2. **Implement automated testing** stages
3. **Add security scanning** (SAST/DAST)
4. **Configure auto-scaling** for production
5. **Set up disaster recovery** procedures

---

**Note**: Customize the configuration based on your specific environment and requirements. Always test in a non-production environment first.
