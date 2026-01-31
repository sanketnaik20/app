#!/bin/bash
set -e

echo "=========================================="
echo "Starting Chat Application"
echo "=========================================="

# Environment variables with defaults
# APP_JAR is set by Dockerfile ENV, but allow override
APP_JAR="${APP_JAR:-*.jar}"
JAVA_OPTS="${JAVA_OPTS:--Xmx512m -Xms256m}"
SPRING_PROFILES_ACTIVE="${SPRING_PROFILES_ACTIVE:-default}"

# Display configuration
echo "Java Options: ${JAVA_OPTS}"
echo "Spring Profiles: ${SPRING_PROFILES_ACTIVE}"
echo "JAR File: ${APP_JAR}"
echo "Java Version:"
java -version
echo "=========================================="

# Pre-startup checks
if [ ! -f "/work/${APP_JAR}" ]; then
    echo "ERROR: JAR file not found: /work/${APP_JAR}"
    exit 1
fi

echo "JAR file found: /work/${APP_JAR}"
ls -lh /work/${APP_JAR}
echo "=========================================="
echo "Starting application..."
echo "=========================================="

# Start the application
# Using exec to ensure proper signal handling
exec java ${JAVA_OPTS} \
    -Dspring.profiles.active=${SPRING_PROFILES_ACTIVE} \
    -jar /work/${APP_JAR} \
    "$@"

# Made with Bob
