FROM eclipse-temurin:21-jdk-jammy

WORKDIR /app

COPY target/camera-status-checker-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 8081

ENTRYPOINT ["java", "-jar", "app.jar"]
