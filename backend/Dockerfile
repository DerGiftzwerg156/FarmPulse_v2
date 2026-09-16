# Mehrstufiger Build: Maven baut das Fat-Jar, das Runtime-Image enthaelt nur
# eine JRE + das fertige Jar. Tests laufen hier bewusst nicht mit (u.a.
# IngestIntegrationTest braucht Testcontainers/Docker-in-Docker) - die
# CI-Pipeline (.github/workflows/test.yml) deckt `mvn test` bereits vollstaendig
# ab, dieses Image baut nur das bereits getestete Artefakt.
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /build

# Abhaengigkeiten zuerst aufloesen, damit dieser (teure) Layer im Docker-Cache
# bleibt, solange sich nur der Quellcode und nicht die pom.xml aendert.
COPY pom.xml .
RUN mvn -B -q dependency:go-offline

COPY src src
RUN mvn -B -q package -DskipTests

# Schlankes Runtime-Image ohne JDK/Maven.
FROM eclipse-temurin:25-jre-alpine
WORKDIR /app
COPY --from=build /build/target/farmpulse-backend-*.jar app.jar

# Docker-spezifische Konfiguration (siehe
# src/main/resources/application-docker.yml) als Standard fuer dieses Image -
# ueberschreibbar per `docker run -e SPRING_PROFILES_ACTIVE=...`.
ENV SPRING_PROFILES_ACTIVE=docker

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
