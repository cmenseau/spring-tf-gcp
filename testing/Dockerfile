FROM eclipse-temurin:17-jdk-alpine as build
WORKDIR /workspace/app

ENV MYAPP_JDBC_URL=jdbc:postgresql://host.docker.internal:5432/todo_db
ENV MYAPP_JDBC_USER=cycy
ENV MYAPP_JDBC_PASS=mysecretpassword

RUN echo ${MYAPP_JDBC_PASS}

COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .
COPY src src

RUN ./mvnw verify