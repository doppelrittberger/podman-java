FROM quay.io/podman/stable

RUN dnf -y install bsdtar containernetworking-cni slirp4netns

RUN curl -fsSL -o /tmp/java.tar.gz https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.9%2B10/OpenJDK21U-jdk_x64_linux_hotspot_21.0.9_10.tar.gz \
 && mkdir -p /usr/share/java \
 && tar xvf /tmp/java.tar.gz -C /usr/share/java --strip-components=1 \
 && rm -f /tmp/java.tar.gz \
 && ln -s /usr/share/java/bin/java /usr/bin/java

RUN curl -fsSL -o /tmp/maven.tar.gz https://archive.apache.org/dist/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz \
 && mkdir -p /usr/share/maven \
 && tar xvf /tmp/maven.tar.gz -C /usr/share/maven --strip-components=1 \
 && rm -f /tmp/maven.tar.gz \
 && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

RUN curl -fsSL -o /tmp/gradle.zip https://services.gradle.org/distributions/gradle-8.3-all.zip \
 && mkdir -p /usr/share/gradle \
 && bsdtar xvf /tmp/gradle.zip -C /usr/share/gradle --strip-components=1 \
 && rm -f /tmp/gradle.zip \
 && ln -s /usr/share/gradle/bin/gradle /usr/bin/gradle

RUN curl -fsSL -o /tmp/go.tar.gz https://go.dev/dl/go1.21.1.linux-amd64.tar.gz \
 && mkdir -p /usr/share/go \
 && tar xvf /tmp/go.tar.gz -C /usr/share/go --strip-components=1 \
 && rm -f /tmp/go.tar.gz \
 && ln -s /usr/share/go/bin/go /usr/bin/go \
 && ln -s /usr/share/go/bin/gofmt /usr/bin/gofmt

ENV JAVA_HOME /usr/share/java
ENV MAVEN_HOME /usr/share/maven
ENV GRADLE_HOME /usr/share/gradle

RUN usermod --add-subgids 65536-165536 podman
RUN usermod --add-subuids 65536-165536 podman
RUN ln -sfv /usr/bin/podman /usr/bin/docker
RUN printf '%s\n' \
    '#!/bin/bash' \
    'set -euo pipefail' \
    '' \
    'podman system service -t 0 tcp:0.0.0.0:2375 &' \
    'service_pid=$!' \
    '' \
    '# Wait for the API to come up, and fail loudly if the service dies or never becomes ready.' \
    'for _ in $(seq 1 30); do' \
    '  if ! kill -0 "$service_pid" 2>/dev/null; then' \
    '    echo "podman system service exited unexpectedly" >&2' \
    '    wait "$service_pid"' \
    '    exit 1' \
    '  fi' \
    '  if curl -fsS -o /dev/null "http://localhost:2375/_ping"; then' \
    '    exit 0' \
    '  fi' \
    '  sleep 1' \
    'done' \
    '' \
    'echo "timed out waiting for podman system service to become ready" >&2' \
    'kill "$service_pid" 2>/dev/null || true' \
    'exit 1' \
    > /usr/bin/start-podman \
 && chmod +x /usr/bin/start-podman

USER podman

ENV DOCKER_HOST="tcp://localhost:2375"
ENV TESTCONTAINERS_RYUK_DISABLED=true

RUN echo -en "[containers]\nvolumes=[\"/proc:/proc\", \"/sys:/sys\"]\ndefault_sysctls=[]\nnetns=\"slirp4netns\"" > /home/podman/.config/containers/containers.conf
RUN echo -en "[storage]\ndriver=\"overlay\"\n[storage.options.overlay]\nignore_chown_errors=\"true\"" > /home/podman/.config/containers/storage.conf

LABEL org.opencontainers.image.title="Podman with Java Docker Image" \
      org.opencontainers.image.description="podman-java" \
      org.opencontainers.image.url="https://github.com/doppelrittberger/podman-java" \
      org.opencontainers.image.source="https://github.com/doppelrittberger/podman-java" \
      org.opencontainers.image.license="Apache 2.0"
