#!/bin/bash
# Download an archive and install it under /usr/share/<name>, linking the given
# binaries into /usr/bin.
#
# Usage: install-tool.sh <name> <url> <binary> [binary...]
set -euo pipefail

name="$1"
url="$2"
shift 2

archive="/tmp/${name}-download"
target="/usr/share/${name}"

curl -fsSL -o "${archive}" "${url}"
mkdir -p "${target}"

case "${url}" in
  *.zip) bsdtar xvf "${archive}" -C "${target}" --strip-components=1 ;;
  *)     tar xvf "${archive}" -C "${target}" --strip-components=1 ;;
esac

rm -f "${archive}"

for binary in "$@"; do
  ln -sfv "${target}/bin/${binary}" "/usr/bin/${binary}"
done
