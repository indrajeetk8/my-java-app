# CI/CD Pipeline Overview

This document provides an overview of the comprehensive CI/CD pipeline implemented for the **My Java App** Spring Boot application.

## 🔄 Pipeline Architecture

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐    ┌──────────────┐
│   Source    │───▶│   Jenkins    │───▶│   Docker    │───▶│ Deployment   │
│   Control   │    │   Pipeline   │    │   Registry  │    │ Environment  │
│   (Git)     │    │              │    │             │    │              │
└─────────────┘    └──────────────┘    └─────────────┘    └──────────────┘
                           │
                           ▼
                   ┌──────────────┐
                   │   Quality    │
                   │   Gates &    │
                   │   Testing    │
                   └──────────────┘
```

## 🚀 Pipeline Stages

### 1. **Checkout** 
- Pulls source code from Git repository
- Captures commit metadata (short hash, timestamp)
- Prepares workspace for build

### 2. **Build**
- Compiles Java source code using Maven
- Downloads dependencies
- Validates compilation success

### 3. **Test**
- Runs unit tests with JUnit
- Generates test reports
- Archives test results for reporting
- Fails pipeline if tests fail

### 4. **Code Quality Analysis** (Parallel)
- **SpotBugs**: Static analysis for bugs and security issues
- **Checkstyle**: Code style and formatting checks
- **PMD**: Code quality and best practices
- **JaCoCo**: Code coverage analysis

### 5. **Package**
- Creates executable JAR file
- Archives build artifacts
- Prepares application for containerization

### 6. **Docker Build**
- Builds Docker image from Dockerfile
- Tags with version and commit hash
- Uses multi-stage builds for optimization

### 7. **Security Scan**
- Vulnerability scanning with Trivy
- Checks for security issues in dependencies
- Container image security analysis

### 8. **Deploy to Nexus**
- Publishes JAR artifacts to Nexus repository
- Only on main/develop branches
- Uses secure credential management

### 9. **Push Docker Image**
- Pushes images to Docker registry
- Tags with version and 'latest'
- Only on main branch for production images

### 10. **Environment Deployment** (Conditional)
- **Development**: Auto-deploy from develop branch
- **Staging**: Auto-deploy from main branch
- **Production**: Manual approval required

### 11. **Production Deployment** (Manual)
- Requires explicit approval
- Supports multiple deployment strategies
- Includes rollback capabilities

## 🔧 Configuration Files

### Core Pipeline Files
- `Jenkinsfile` - Main pipeline definition
- `Dockerfile` - Container image specification
- `pom.xml` - Maven build and plugin configuration

### Quality & Analysis
- `sonar-project.properties` - SonarQube configuration
- `checkstyle.xml` - Code style rules
- JaCoCo integration for coverage

### Docker Compose Files
- `docker-compose.dev.yml` - Development environment
- `docker-compose.staging.yml` - Staging environment with monitoring

### Deployment Scripts
- `deploy-dev.bat` - Development deployment
- `deploy-prod.bat` - Production deployment with safety checks

## 🎛️ Environment-Specific Configurations

### Development Environment
```yaml
Features:
- Auto-deployment on develop branch
- H2 in-memory database
- Debug logging enabled
- Hot-reload with DevTools
- Minimal resource constraints
```

### Staging Environment  
```yaml
Features:
- Auto-deployment on main branch
- PostgreSQL database
- Nginx reverse proxy
- Prometheus monitoring
- Production-like resources
```

### Production Environment
```yaml
Features:
- Manual deployment approval
- Enhanced security scanning
- Blue-green deployment support
- Comprehensive health checks
- Rollback capabilities
- Resource limits and monitoring
```

## 🔐 Security Features

### Pipeline Security
- Credential management via Jenkins credentials store
- No hardcoded secrets in pipeline files
- Container image vulnerability scanning
- Security-focused static analysis (FindSecBugs)

### Deployment Security
- Non-root container user
- Resource limits and constraints
- Health checks and readiness probes
- Automated rollback on failure

## 📊 Quality Gates

### Code Quality Thresholds
- **Line Coverage**: Minimum 80% (configurable)
- **Code Style**: Checkstyle compliance
- **Security**: No high/critical vulnerabilities
- **Performance**: JVM tuning for each environment

### Test Requirements
- All unit tests must pass
- Integration tests in staging
- Smoke tests in production deployment
- Health check validation

## 🚨 Monitoring & Alerting

### Application Monitoring
- Spring Boot Actuator endpoints
- Prometheus metrics collection
- Health check endpoints
- Performance monitoring

### Pipeline Notifications
- Slack integration for build status
- Email notifications for failures
- Deployment success/failure alerts
- Quality gate threshold breaches

## 🔄 Deployment Strategies

### 1. Simple Deployment (Development)
```bash
docker run -d --name my-java-app-dev -p 8080:8080 my-java-app:latest
```

### 2. Blue-Green Deployment (Production)
```bash
# Deploy to green environment
# Health check validation
# Switch traffic
# Cleanup blue environment
```

### 3. Rolling Deployment (Future)
- Kubernetes-based rolling updates
- Zero-downtime deployments
- Gradual traffic shifting

## 📁 Directory Structure
```
my-java-app/
├── src/                          # Source code
├── target/                       # Build artifacts
├── docker-compose.*.yml          # Environment-specific compose files
├── deploy-*.bat                  # Deployment scripts
├── Jenkinsfile                   # CI/CD pipeline definition
├── Dockerfile                    # Container specification
├── sonar-project.properties      # SonarQube config
├── checkstyle.xml               # Code style rules
├── JENKINS_SETUP.md             # Jenkins setup guide
├── CI-CD-OVERVIEW.md            # This file
└── README.md                    # Project documentation
```

## 🚀 Getting Started

### Prerequisites
1. Jenkins server with required plugins
2. Docker runtime environment
3. Maven 3.8+ and Java 11+
4. Nexus repository (optional)
5. SonarQube server (optional)

### Setup Steps
1. **Configure Jenkins**: Follow `JENKINS_SETUP.md`
2. **Set up credentials**: Nexus, Docker registry, Git access
3. **Create pipeline job**: Point to your repository
4. **Configure environments**: Update compose files for your infrastructure
5. **Run first build**: Test the pipeline end-to-end

### Running Locally
```bash
# Development environment
docker-compose -f docker-compose.dev.yml up -d

# Staging environment
docker-compose -f docker-compose.staging.yml up -d

# Manual deployment
deploy-dev.bat latest
deploy-prod.bat v2.0.0-abc123
```

## 🔧 Customization

### Environment Variables
```bash
# Jenkins Pipeline
MAVEN_OPTS="-Xmx1024m"
DOCKER_REGISTRY="your-registry.com"
NEXUS_URL="https://nexus.company.com"

# Application
SPRING_PROFILES_ACTIVE="prod"
DATABASE_URL="jdbc:postgresql://db:5432/myapp"
```

### Plugin Configuration
- Modify `pom.xml` for different quality thresholds
- Update `checkstyle.xml` for coding standards
- Adjust `sonar-project.properties` for analysis rules

## 📈 Performance Optimization

### Build Performance
- Maven dependency caching
- Parallel test execution
- Multi-stage Docker builds
- Incremental builds where possible

### Runtime Performance
- JVM tuning per environment
- Resource limits and requests
- Health check optimization
- Efficient container layering

## 🆘 Troubleshooting

### Common Issues
1. **Build failures**: Check Maven logs, dependency conflicts
2. **Test failures**: Review test reports, environment setup
3. **Docker issues**: Verify daemon, image builds, registry access
4. **Deployment failures**: Check health endpoints, logs, resource availability

### Debug Commands
```bash
# Check application status
docker logs my-java-app-prod

# Health check
curl http://localhost:8080/actuator/health

# Jenkins pipeline logs
# Available in Jenkins UI build console

# Maven debug build
mvn clean install -X
```

## 🔮 Future Enhancements

### Pipeline Improvements
- [ ] Kubernetes deployment support
- [ ] Multi-region deployment
- [ ] Database migration handling
- [ ] Performance testing integration
- [ ] Automated security scanning

### Monitoring & Observability
- [ ] Distributed tracing (Jaeger)
- [ ] Centralized logging (ELK stack)
- [ ] Custom metrics and dashboards
- [ ] Alerting rules and runbooks

### Quality & Testing
- [ ] Contract testing (Pact)
- [ ] End-to-end test automation
- [ ] Chaos engineering tests
- [ ] Load and performance testing

---

This CI/CD pipeline provides a robust, scalable, and secure deployment process for the Spring Boot application. It follows industry best practices and can be adapted to various infrastructure environments and deployment strategies.
