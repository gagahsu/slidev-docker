# ---- 第一階段：用 Gradle 編譯，本機不需要裝 JDK ----
FROM gradle:8.14-jdk21 AS build
WORKDIR /src
COPY gradlew settings.gradle build.gradle ./
COPY gradle ./gradle
RUN ./gradlew dependencies --no-daemon
COPY src ./src
RUN ./gradlew bootJar --no-daemon

# ---- 第二階段：只留 JRE 跟打包好的 jar ----
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
# 建立非 root 使用者，並先建好 logs 目錄（之後掛 Volume 才有寫入權限）
RUN addgroup -S app && adduser -S app -G app && mkdir logs && chown app:app logs
COPY --from=build /src/build/libs/survey-api.jar app.jar
USER app
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
