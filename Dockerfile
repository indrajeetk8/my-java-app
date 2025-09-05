FROM openjdk:11-jre-slim
COPY target/my-java-app-1.0.0.jar /app/my-java-app.jar
ENTRYPOINT ["java", "-jar", "/app/my-java-app.jar"]
