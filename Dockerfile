# Multi-stage build for optimization
FROM eclipse-temurin:17-jdk-alpine as build

# Set working directory
WORKDIR /workspace/app

# Copy Maven files
COPY pom.xml .
COPY src src

# Build the application (optional - can be done in Jenkins ok )
# RUN ./mvnw install -DskipTests

# Runtime stage
FROM eclipse-temurin:17-jre-alpine

# Create app directory
WORKDIR /app

# Create non-root user for security and install curl for health check
RUN apk add --no-cache curl && \
    addgroup -S appgroup && \
    adduser -S -G appgroup appuser

# Copy the jar file (version will be updated by Jenkins)
COPY target/my-java-app-*.jar app.jar

# Change ownership to non-root user
RUN chown appuser:appgroup /app/app.jar

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

# Run the Spring Boot application
ENTRYPOINT ["java", "-jar", "/app/app.jar"]

# Optional: Add JVM tuning parameters
# ENTRYPOINT ["java", "-Xmx512m", "-Xms256m", "-jar", "/app/app.jar"]

