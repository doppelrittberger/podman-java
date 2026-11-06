FROM quay.io/podman/stable

# Toolchain downloads are pinned as full URLs so a bump is a single-line edit and a rebuild is reproducible.
# Temurin JDK 21 (LTS) - the default JDK for Maven and Gradle builds.
ARG TEMURIN_URL=https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.13%2B9/OpenJDK21U-jdk_x64_linux_hotspot_21.0.13_9.tar.gz
# GraalVM Community JDK 25 - ships native-image since GraalVM 23, so no `gu install` step.
ARG GRAALVM_URL=https://github.com/graalvm/graalvm-ce-builds/releases/download/graal-25.5.5.0.3/graalvm-community-jdk-25i5-25.0.5.0.3_linux-x64_bin.tar.gz
ARG MAVEN_VERSION=3.10.0
ARG GRADLE_VERSION=8.14.6
ARG GO_VERSION=1.27.3

RUN dnf -y install bsdtar containernetworking-cni slirp4netns

RUN curl -fsSL -o /tmp/java.tar.gz "${TEMURIN_URL}" \
&& mkdir -p /usr/share/java \
&& tar xf /tmp/java.tar.gz -C /usr/share/java --strip-components=1 \
&& rm -f /tmp/java.tar.gz \
&& ln -s /usr/share/java/bin/java /usr/bin/java

# GraalVM lives next to Temurin instead of replacing it, so existing JDK 21 builds keep working.
# For a native build: JAVA_HOME=$GRAALVM_HOME mvn -Pnative package
RUN curl -fsSL -o /tmp/graalvm.tar.gz "${GRAALVM_URL}" \
&& mkdir -p /usr/share/graalvm \
&& tar xf /tmp/graalvm.tar.gz -C /usr/share/graalvm --strip-components=1 \
&& rm -f /tmp/graalvm.tar.gz

RUN curl -fsSL -o /tmp/maven.tar.gz "https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" \
&& mkdir -p /usr/share/maven \
&& tar xf /tmp/maven.tar.gz -C /usr/share/maven --strip-components=1 \
&& rm -f /tmp/maven.tar.gz \
&& ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

RUN curl -fsSL -o /tmp/gradle.zip "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-all.zip" \
&& mkdir -p /usr/share/gradle \
&& bsdtar xf /tmp/gradle.zip -C /usr/share/gradle --strip-components=1 \
&& rm -f /tmp/gradle.zip \
&& ln -s /usr/share/gradle/bin/gradle /usr/bin/gradle

RUN curl -fsSL -o /tmp/go.tar.gz "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" \
&& mkdir -p /usr/share/go \
&& tar xf /tmp/go.tar.gz -C /usr/share/go --strip-components=1 \
&& rm -f /tmp/go.tar.gz \
&& ln -s /usr/share/go/bin/go /usr/bin/go \
&& ln -s /usr/share/go/bin/gofmt /usr/bin/gofmt

ENV JAVA_HOME /usr/share/java
ENV MAVEN_HOME /usr/share/maven
ENV GRADLE_HOME /usr/share/gradle
ENV GRAALVM_HOME /usr/share/graalvm
# GraalVM is appended so `java`/`javac` still resolve to Temurin; only `native-image` is picked up from there.
ENV PATH $PATH:/usr/share/graalvm/bin

# Fail the image build if a toolchain is broken, instead of at pipeline runtime.
RUN java -version \
&& mvn -v \
&& gradle -v \
&& go version \
&& native-image --version

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
