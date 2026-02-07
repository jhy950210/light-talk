# Stage 1: Build
FROM gradle:8.10.2-jdk17 AS build
WORKDIR /app
COPY . .
RUN gradle :module-app:bootJar -x test --no-daemon

# Stage 2: Runtime
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=build /app/module-app/build/libs/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
