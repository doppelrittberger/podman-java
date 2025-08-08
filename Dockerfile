FROM quay.io/podman/stable

RUN dnf -y install bsdtar containernetworking-cni slirp4netns

RUN curl -fsSL -o /tmp/java.tar.gz https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.8%2B9/OpenJDK21U-jdk_x64_linux_hotspot_21.0.8_9.tar.gz \
 && mkdir -p /usr/share/java \
 && tar xvf /tmp/java.tar.gz -C /usr/share/java --strip-components=1 \
 && rm -f /tmp/java.tar.gz \
 && ln -s /usr/share/java/bin/java /usr/bin/java

RUN curl -fsSL -o /tmp/maven.tar.gz https://archive.apache.org/dist/maven/maven-3/3.9.4/binaries/apache-maven-3.9.4-bin.tar.gz \
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
