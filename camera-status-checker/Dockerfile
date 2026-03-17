# ---------- Stage 1: Build ----------
FROM maven:3.9.9-eclipse-temurin-21 AS builder

WORKDIR /build

# copy pom ก่อน เพื่อใช้ cache dependency
COPY pom.xml .
RUN mvn -B -q -e -DskipTests dependency:go-offline

# copy source code
COPY src ./src

# build jar
RUN mvn clean package -DskipTests


# ---------- Stage 2: Run ----------
FROM eclipse-temurin:21-jdk-jammy

WORKDIR /app

# copy jar จาก stage แรก
COPY --from=builder /build/target/*.jar app.jar

EXPOSE 8081

ENTRYPOINT ["java", "-jar", "app.jar"]
