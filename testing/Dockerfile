FROM eclipse-temurin:17-jdk-alpine as build
WORKDIR /workspace/app

COPY ../mvnw .
COPY ../.mvn .mvn
COPY ../pom.xml .
COPY ../src src

RUN ../mvnw verify