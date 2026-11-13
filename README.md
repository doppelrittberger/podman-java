# podman-toolchain

[quay.io/podman/stable](https://quay.io/repository/podman/stable) with a JVM/Go toolchain
(Temurin JDK 21, GraalVM, Maven, Gradle, Go), `bubblewrap`, `socat` and the `pasta` network
backend.

`podman` runs rootless as the unprivileged `podman` user (uid 1000), `docker` is aliased to
it, and `/usr/bin/start-podman` exposes the Docker API on port 2375.

## Running unprivileged

Rootless podman-in-podman needs unprivileged user namespaces, `/dev/fuse` for the overlay
store and `/dev/net/tun` for `pasta`:

    podman run --rm -it \
      --device /dev/fuse --device /dev/net/tun \
      -v "$PWD":/workspace -w /workspace \
      doppelrittberger/podman-toolchain

With Docker add `--security-opt seccomp=unconfined`: Docker's default seccomp profile denies
`clone(CLONE_NEWUSER)`, which both rootless podman and bubblewrap need.

### bubblewrap

`bwrap` creates its own user namespace and mounts a fresh `/proc`. Containers mask parts of
`/proc`, which makes that mount fail with
`bwrap: Can't mount proc on /proc: Operation not permitted`. Under podman, unmask those paths:

    podman run --rm -it --security-opt unmask=all ... doppelrittberger/podman-toolchain

Docker has no `unmask` option: pass `--bind /proc /proc` instead of `--proc /proc` to bwrap,
or run the container `--privileged`.

`socat` needs no extra privileges.
