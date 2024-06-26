# stage 1 : test and build jar

FROM eclipse-temurin:17-jdk-alpine as build
WORKDIR /workspace/app

ENV MYAPP_JDBC_URL=jdbc:postgresql://host.docker.internal:5432/todo_db
ENV MYAPP_JDBC_USER=cycy
ENV MYAPP_JDBC_PASS=mysecretpassword

COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .
COPY src src
COPY .git .git

# build, run unit and integration tests
RUN ./mvnw install

# stage 2 : image with the jar

FROM eclipse-temurin:17-jdk-alpine AS image
VOLUME /tmp
COPY --from=build /workspace/app/target/*.jar app.jar
ENTRYPOINT ["java","-jar","/app.jar"]
