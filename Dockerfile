FROM mgoltzsche/podman:latest

RUN apk add git openjdk17 maven

CMD ["podman", "system", "service", "-t", "0", "tcp:0.0.0.0:2375"]

LABEL org.opencontainers.image.title="Podman with maven Docker Image" \
      org.opencontainers.image.description="podman-maven" \
      org.opencontainers.image.url="https://github.com/doppelrittberger/podman-maven" \
      org.opencontainers.image.source="https://github.com/doppelrittberger/podman-maven" \
      org.opencontainers.image.license="Apache 2.0"
