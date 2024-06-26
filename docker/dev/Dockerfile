FROM eclipse-temurin:17-jdk-alpine AS build-test
WORKDIR /workspace/app

COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .
COPY src src
COPY ./.git .git

# ENTRYPOINT ./mvnw package -e && java -jar /workspace/app/target/*.jar 
# only UT

ENTRYPOINT ./mvnw install -e && java -jar /workspace/app/target/*.jar
# both IT an UT

