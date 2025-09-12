# My Java App

A simple Java application with Maven build system and Nexus repository deployment.

## 📋 Prerequisites

- **Java 11** or higher
- **Maven 3.6+**
- **Docker** (for local Nexus)
- **Git**

## 🚀 Quick Start

### 1. Clone and Build
git clone <your-repo-url>
cd my-java-app
mvn clean compile
```

### 2. Run Tests
```bash
mvn test
```

### 3. Package
```bash
mvn clean package
```

### 4. Run Application
```bash
java -jar target/my-java-app-1.0.0.jar
```

## 📦 Nexus Repository Deployment

This project is configured to deploy to Nexus Repository Manager.

### Local Nexus Setup

#### 1. Start Local Nexus with Docker
```bash
# Start Nexus container
docker run -d -p 8081:8081 --name nexus sonatype/nexus3

# Get admin password (wait ~30 seconds for startup)
docker exec nexus cat /nexus-data/admin.password
```

#### 2. Initial Setup
1. Open http://localhost:8081
2. Login with `admin` and the generated password
3. Complete the setup wizard
4. Change admin password

#### 3. Configure Maven Settings
Create or update `~/.m2/settings.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0">
    <servers>
        <server>
            <id>nexus-releases</id>
            <username>${env.NEXUS_USERNAME}</username>
            <password>${env.NEXUS_PASSWORD}</password>
        </server>
        <server>
            <id>nexus-snapshots</id>
            <username>${env.NEXUS_USERNAME}</username>
            <password>${env.NEXUS_PASSWORD}</password>
        </server>
    </servers>
</settings>
```

#### 4. Set Environment Variables
```bash
# Windows (PowerShell)
$env:NEXUS_USERNAME="admin"
$env:NEXUS_PASSWORD="your-password"

# Linux/macOS
export NEXUS_USERNAME=admin
export NEXUS_PASSWORD=your-password
```

### Remote Nexus Setup

For production deployment, update the repository URLs in `pom.xml`:

```xml
<distributionManagement>
    <repository>
        <id>nexus-releases</id>
        <name>Nexus Release Repository</name>
        <url>https://your-nexus-server.com/repository/maven-releases/</url>
    </repository>
    <snapshotRepository>
        <id>nexus-snapshots</id>
        <name>Nexus Snapshot Repository</name>
        <url>https://your-nexus-server.com/repository/maven-snapshots/</url>
    </snapshotRepository>
</distributionManagement>
```

## 🔄 Deployment Commands

### Deploy Snapshot Version
```bash
# Ensure version ends with -SNAPSHOT in pom.xml
mvn clean deploy
```

### Deploy Release Version
```bash
# Remove -SNAPSHOT from version in pom.xml
mvn clean deploy
```

## 📁 Project Structure

```
my-java-app/
├── src/
│   ├── main/
│   │   └── java/
│   │       └── com/
│   │           └── example/
│   │               └── App.java
│   └── test/
│       └── java/
│           └── com/
│               └── example/
│                   └── AppTest.java
├── pom.xml
├── README.md
└── .gitignore
```

## 🔧 Configuration Files

### pom.xml Features
- **Group ID**: `com.example`
- **Artifact ID**: `my-java-app`
- **Java Version**: 11
- **Dependencies**: JUnit 4.13.2
- **Nexus Distribution Management**: Configured for both releases and snapshots

### Maven Settings
- Environment variable based authentication
- Separate server configurations for releases and snapshots

## 🐳 Docker Commands

### Nexus Container Management
```bash
# Start existing container
docker start nexus

# Stop container
docker stop nexus

# View logs
docker logs nexus

# Remove container (will lose data)
docker rm nexus

# Fresh start with persistent storage
docker run -d -p 8081:8081 --name nexus \
  -v nexus-data:/nexus-data \
  sonatype/nexus3
```

## 🔒 Security Best Practices

1. **Never commit credentials** to version control
2. **Use environment variables** for sensitive data
3. **Enable HTTPS** in production Nexus
4. **Regular password rotation**
5. **Principle of least privilege** for user accounts

## 📊 Available Repositories

### Local Nexus (Default)
- **Releases**: http://localhost:8081/repository/maven-releases/
- **Snapshots**: http://localhost:8081/repository/maven-snapshots/
- **Public Group**: http://localhost:8081/repository/maven-public/

### Using Artifacts in Other Projects

Add to your `pom.xml`:

```xml
<repositories>
    <repository>
        <id>nexus-public</id>
        <url>http://localhost:8081/repository/maven-public/</url>
    </repository>
</repositories>

<dependencies>
    <dependency>
        <groupId>com.example</groupId>
        <artifactId>my-java-app</artifactId>
        <version>1.0.0</version>
    </dependency>
</dependencies>
```

## 🚀 CI/CD Integration

For automated deployment, set these environment variables in your CI/CD pipeline:
- `NEXUS_USERNAME`
- `NEXUS_PASSWORD`
- `NEXUS_URL` (if different from localhost)

Example GitHub Actions workflow:
```yaml
env:
  NEXUS_USERNAME: ${{ secrets.NEXUS_USERNAME }}
  NEXUS_PASSWORD: ${{ secrets.NEXUS_PASSWORD }}

steps:
  - name: Deploy to Nexus
    run: mvn clean deploy
```

## 📝 Version Management

### Semantic Versioning
- **Major**: Incompatible API changes (1.0.0 → 2.0.0)
- **Minor**: New functionality, backwards compatible (1.0.0 → 1.1.0)  
- **Patch**: Bug fixes, backwards compatible (1.0.0 → 1.0.1)

### Development Workflow
1. Work with `-SNAPSHOT` versions during development
2. Remove `-SNAPSHOT` for releases
3. Increment version after release
4. Add `-SNAPSHOT` back for next development cycle

## 🆘 Troubleshooting

### Common Issues

**401 Unauthorized**
- Check username/password in settings.xml
- Verify environment variables are set
- Confirm user has deployment permissions

**403 Forbidden**
- Repository might not allow deployments
- Check user roles in Nexus UI
- Verify repository configuration

**Connection Issues**
- Confirm Nexus is running: `docker ps`
- Check port 8081 is accessible
- Verify URL in pom.xml

**Build Failures**
- Run `mvn clean` to clear build cache
- Check Java version compatibility
- Verify dependencies are available

## 📞 Support

For issues and questions:
1. Check this README
2. Review Nexus logs: `docker logs nexus`
3. Check Maven debug output: `mvn -X clean deploy`

## 📄 License

This project is licensed under the MIT License.
