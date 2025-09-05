FROM openjdk:11-jre-slim
WORKDIR /app
COPY target/my-java-app-1.0-SNAPSHOT.jar my-java-app.jar
ENTRYPOINT ["java", "-cp", "my-java-app.jar", "com.example.App"]

