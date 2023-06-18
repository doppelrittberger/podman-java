FROM quay.io/podman/stable

RUN dnf -y install git

RUN curl -fsSL -o /tmp/java.tar.gz https://download.java.net/java/GA/jdk17.0.2/dfd4a8d0985749f896bed50d7138ee7f/8/GPL/openjdk-17.0.2_linux-x64_bin.tar.gz \
 && mkdir -p /usr/share/java \
 && tar xvf /tmp/java.tar.gz -C /usr/share/java --strip-components=1 \
 && rm -f /tmp/java.tar.gz \
 && ln -s /usr/share/java/bin/java /usr/bin/java

RUN java -version

RUN curl -fsSL -o /tmp/maven.tar.gz https://dlcdn.apache.org/maven/maven-3/3.9.2/binaries/apache-maven-3.9.2-bin.tar.gz \
 && mkdir -p /usr/share/maven \
 && tar xvf /tmp/maven.tar.gz -C /usr/share/maven --strip-components=1 \
 && rm -f /tmp/maven.tar.gz \
 && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

RUN mvn -version

ENV JAVA_HOME /usr/share/java
ENV MAVEN_HOME /usr/share/maven

RUN mkdir -p /dev/net \
 && mknod /dev/net/tun c 10 200 \
 && chmod 666 /dev/net/tun

USER podman

CMD ["podman", "system", "service", "-t", "0", "tcp:0.0.0.0:2375"]

LABEL org.opencontainers.image.title="Podman with maven Docker Image" \
      org.opencontainers.image.description="podman-maven" \
      org.opencontainers.image.url="https://github.com/doppelrittberger/podman-maven" \
      org.opencontainers.image.source="https://github.com/doppelrittberger/podman-maven" \
      org.opencontainers.image.license="Apache 2.0"
