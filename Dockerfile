FROM quay.io/podman/stable

RUN dnf -y install bsdtar containernetworking-cni slirp4netns

COPY scripts/install-tool.sh /usr/local/bin/install-tool
RUN chmod +x /usr/local/bin/install-tool

RUN install-tool java https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.9%2B10/OpenJDK21U-jdk_x64_linux_hotspot_21.0.9_10.tar.gz java
RUN install-tool maven https://archive.apache.org/dist/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz mvn
RUN install-tool gradle https://services.gradle.org/distributions/gradle-8.3-all.zip gradle
RUN install-tool go https://go.dev/dl/go1.21.1.linux-amd64.tar.gz go gofmt

ENV JAVA_HOME /usr/share/java
ENV MAVEN_HOME /usr/share/maven
ENV GRADLE_HOME /usr/share/gradle

RUN usermod --add-subgids 65536-165536 podman \
 && usermod --add-subuids 65536-165536 podman \
 && ln -sfv /usr/bin/podman /usr/bin/docker
RUN echo -en "#!/bin/bash\npodman system service -t 0 tcp:0.0.0.0:2375 &" > /usr/bin/start-podman \
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
