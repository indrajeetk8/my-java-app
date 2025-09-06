# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

This is a simple Java 11 application built with Maven. The project follows standard Maven directory conventions and includes Docker containerization support.

## Build System & Commands

This project uses Maven for build management. Key commands:

### Build and Test
```bash
# Clean and compile
mvn clean compile

# Run all tests
mvn test

# Run a specific test class
mvn test -Dtest=AppTest

# Package the application into a JAR
mvn package

# Clean, compile, test, and package
mvn clean package
```

### Development
```bash
# Run the application directly
mvn exec:java -Dexec.mainClass="com.example.App"

# Or after packaging, run the JAR
java -jar target/my-java-app-1.0.0.jar
```

### Docker
```bash
# Build Docker image (requires JAR to be built first)
mvn package && docker build -t my-java-app .

# Run containerized application
docker run my-java-app
```

## Code Architecture

### Project Structure
- **Main application**: `src/main/java/com/example/App.java` - Entry point with main method
- **Tests**: `src/test/java/com/example/AppTest.java` - JUnit 3 test suite
- **Build configuration**: `pom.xml` - Maven configuration targeting Java 11
- **Containerization**: `Dockerfile` - Uses OpenJDK 11 JRE slim image

### Key Details
- **Java Version**: 11 (configured in pom.xml)
- **Package Structure**: `com.example` namespace
- **Testing Framework**: JUnit 3 (legacy TestCase style)
- **Main Class**: `com.example.App`
- **Artifact**: `my-java-app-1.0.0.jar`

The application currently outputs "Hello, CI/CD World!" indicating it may be used for CI/CD demonstration purposes.
