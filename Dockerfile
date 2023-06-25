FROM quay.io/podman/stable

RUN dnf -y install bsdtar

RUN curl -fsSL -o /tmp/java.tar.gz https://download.java.net/java/GA/jdk17.0.2/dfd4a8d0985749f896bed50d7138ee7f/8/GPL/openjdk-17.0.2_linux-x64_bin.tar.gz \
 && mkdir -p /usr/share/java \
 && tar xvf /tmp/java.tar.gz -C /usr/share/java --strip-components=1 \
 && rm -f /tmp/java.tar.gz \
 && ln -s /usr/share/java/bin/java /usr/bin/java

RUN curl -fsSL -o /tmp/maven.tar.gz https://dlcdn.apache.org/maven/maven-3/3.9.2/binaries/apache-maven-3.9.2-bin.tar.gz \
 && mkdir -p /usr/share/maven \
 && tar xvf /tmp/maven.tar.gz -C /usr/share/maven --strip-components=1 \
 && rm -f /tmp/maven.tar.gz \
 && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

RUN curl -fsSL -o /tmp/gradle.zip https://services.gradle.org/distributions/gradle-8.1.1-all.zip \
 && mkdir -p /usr/share/gradle \
 && bsdtar xvf /tmp/gradle.zip -C /usr/share/gradle --strip-components=1 \
 && rm -f /tmp/gradle.zip \
 && ln -s /usr/share/gradle/bin/gradle /usr/bin/gradle

ENV JAVA_HOME /usr/share/java
ENV MAVEN_HOME /usr/share/maven
ENV GRADLE_HOME /usr/share/gradle

RUN ln -sfv /usr/bin/podman /usr/bin/docker

USER podman

ENV DOCKER_HOST="tcp://localhost:2375"
ENV TESTCONTAINERS_RYUK_DISABLED=true

RUN echo -en "[containers]\nvolumes = [\"/proc:/proc\", \"/sys:/sys\"]\ndefault_sysctls = []\nnetns=\"slirp4netns\"" > /home/podman/.config/containers/containers.conf
RUN echo -en "#!/bin/bash\npodman system service -t 0 tcp:0.0.0.0:2375 &" > /usr/bin/start-podman \
 && chmod +x /usr/bin/start-podman

ENTRYPOINT ["start-podman"]

LABEL org.opencontainers.image.title="Podman with Java Docker Image" \
      org.opencontainers.image.description="podman-java" \
      org.opencontainers.image.url="https://github.com/doppelrittberger/podman-java" \
      org.opencontainers.image.source="https://github.com/doppelrittberger/podman-java" \
      org.opencontainers.image.license="Apache 2.0"
