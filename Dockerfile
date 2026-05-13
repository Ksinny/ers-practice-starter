# ============ (1) Builder ============
ARG BUILDER_IMAGE=gradle:7.6.0-jdk17
ARG RUNTIME_IMAGE=eclipse-temurin:17-jdk-alpine

# 1. JDK 이미지를 베이스로 사용
FROM ${BUILDER_IMAGE} AS builder

USER root
WORKDIR /app
ENV GRADLE_USER_HOME=/home/gradle/.gradle
RUN mkdir -p $GRADLE_USER_HOME && chown -R gradle:gradle /home/gradle /app
USER gradle

COPY --chown=gradle:gradle gradlew ./
COPY --chown=gradle:gradle gradle ./gradle
COPY --chown=gradle:gradle build.gradle settings.gradle ./
RUN chmod +x ./gradlew
RUN ./gradlew --no-daemon --refresh-dependencies dependencies || true

COPY --chown=gradle:gradle src ./src
RUN ./gradlew clean build --no-daemon --no-parallel -x test


# ============ (2) Runtime ============
FROM ${RUNTIME_IMAGE}
WORKDIR /app

COPY --from=builder /app/build/libs/*.jar app.jar
ENV SPRING_PROFILES_ACTIVE=prod

# 3. 컨테이너가 실행될 때 실행할 명령어
ENTRYPOINT ["java","-jar","/app.jar"]

# 4. 서비스 포트 노출 (Spring Boot 기본 8080)
EXPOSE 8080