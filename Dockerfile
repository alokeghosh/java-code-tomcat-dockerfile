# ----------------------------------------------------------------------
# STAGE 1: The Builder Stage - Compiles the Java code and creates the WAR file.
# ----------------------------------------------------------------------
FROM maven:3.9.5-eclipse-temurin-17 AS builder

# Set the working directory
WORKDIR /app

# Copy the Maven project file first for better Docker layer caching
COPY pom.xml .

# Download dependencies (if they change less frequently than the code)
# -B: Batch mode, non-interactive
RUN mvn dependency:go-offline -B

# Copy the rest of the source code
COPY src/ ./src/

# Package the application. This creates target/my-tomcat-app.war
RUN mvn package -DskipTests

# ----------------------------------------------------------------------
# STAGE 2: The Final Stage - Deploys the WAR file onto a Tomcat server.
# ----------------------------------------------------------------------
# Use a Tomcat image with a minimal JRE
#FROM tomcat:9.0-jre17-temurin
FROM tomcat:10.1.13-jre17-temurin-jammy
# Remove the default ROOT application to deploy our WAR at the root context.
RUN rm -rf /usr/local/tomcat/webapps/ROOT

# Copy the WAR file from the 'builder' stage into the Tomcat webapps directory.
# The WAR is renamed to ROOT.war so the application is accessible at http://<host>:<port>/
# The WAR file name 'my-tomcat-app.war' comes from <finalName> in pom.xml.
COPY --from=builder /app/target/my-tomcat-app.war /usr/local/tomcat/webapps/ROOT.war

# Tomcat's default HTTP port
EXPOSE 8080


# The base Tomcat image already has a CMD to start the server (catalina.sh run)
