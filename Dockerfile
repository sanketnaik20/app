ARG UBI_IMAGE=ubi8/ubi:8.10

# ============================================================================
# Stage 1: Initial - Downloads JAR from Artifactory
# ============================================================================
FROM registry.access.redhat.com/${UBI_IMAGE} AS initial

# Build arguments for Artifactory access
ARG ARTIFACTORY_USER
ARG ARTIFACTORY_PASSWORD
ARG ARTIFACTORY_MAVEN_URL=na.artifactory.swg-devops.com/artifactory/ip-devops-team-sandbox-maven-local
ARG GROUP_ID=com/chat
ARG ARTIFACT_ID=app
ARG FULL_VERSION

# Install only what is needed to download artifacts in the initial container
# This container is not used in the final packaging
RUN dnf update -y \
    && dnf install -y curl \
    && dnf clean all \
    && rm -rf /var/cache/yum /var/cache/dnf \
    && mkdir work

WORKDIR /work

# Download the application jar with original name from Artifactory
RUN echo "========================================" \
    && echo "Downloading JAR from Artifactory" \
    && echo "========================================" \
    && echo "Artifact: ${GROUP_ID}/${ARTIFACT_ID}/${FULL_VERSION}" \
    && echo "JAR Name: ${ARTIFACT_ID}-${FULL_VERSION}.jar" \
    && echo "URL: https://${ARTIFACTORY_MAVEN_URL}/hello-world/${GROUP_ID}/${ARTIFACT_ID}/${FULL_VERSION}/${ARTIFACT_ID}-${FULL_VERSION}.jar" \
    && echo "========================================" \
    && curl -f -u ${ARTIFACTORY_USER}:${ARTIFACTORY_PASSWORD} \
       -o ${ARTIFACT_ID}-${FULL_VERSION}.jar \
       "https://${ARTIFACTORY_MAVEN_URL}/hello-world/${GROUP_ID}/${ARTIFACT_ID}/${FULL_VERSION}/${ARTIFACT_ID}-${FULL_VERSION}.jar" \
    && echo "========================================" \
    && echo "Download successful!" \
    && ls -lh ${ARTIFACT_ID}-${FULL_VERSION}.jar \
    && echo "========================================"

# ============================================================================
# Stage 2: Runtime - Create final application image
# From here down is the actual container built for the application
# Before are the multi stage docker images used to build specific layers
# ============================================================================
FROM registry.access.redhat.com/${UBI_IMAGE}

# Build arguments for metadata
ARG APP_USER=spring
ARG ARTIFACT_ID=app
ARG FULL_VERSION
ARG BUILD_LABEL
ARG GIT_TAG
ARG GIT_REPOSITORY
ARG GIT_COMMIT_SHA
ARG GIT_BRANCH

# Labels for traceability and metadata
LABEL name="chat-app" \
      git-tag="${GIT_TAG}" \
      git-repository="${GIT_REPOSITORY}" \
      git-commit-sha="${GIT_COMMIT_SHA}" \
      git-branch="${GIT_BRANCH}" \
      vendor="Your Company" \
      version="${FULL_VERSION}" \
      build-label="${BUILD_LABEL}" \
      summary="Spring Boot Chat Application" \
      description="WebSocket-based real-time chat application built with Spring Boot"

# Environment variable for JAR name (keeps original name from Artifactory)
ENV APP_JAR="${ARTIFACT_ID}-${FULL_VERSION}.jar"

# Copy entrypoint script and JAR from initial stage (with original name)
COPY entrypoint.sh /work/
COPY --from=initial /work/${ARTIFACT_ID}-${FULL_VERSION}.jar /work/

# Upgrade the image, install Java, and set permissions
RUN dnf clean all \
    && dnf update -y \
    && dnf install -y java-17-openjdk-headless \
    && rm -rf /var/cache/yum \
    && rm -rf /var/cache/dnf \
    && chmod +x /work/entrypoint.sh

# Create non-root user for security
RUN useradd -r -u 1001 -g 0 ${APP_USER} \
    && chown -R ${APP_USER}:0 /work \
    && chmod -R g=u /work

# Expose application port
EXPOSE 8080

# Switch to non-root user
USER ${APP_USER}

# Set working directory
WORKDIR /work

# Set entrypoint
ENTRYPOINT ["/work/entrypoint.sh"]