# check=error=true
# One image, two uses: `docker compose up` (standalone) and a Home Assistant add-on.
# Home Assistant passes BUILD_FROM/BUILD_ARCH from build.yaml. Standalone builds (compose, plain
# `docker build`) fall back to the multi-arch Home Assistant base image and the build machine's
# architecture.
ARG BUILD_FROM=ghcr.io/home-assistant/base:3.22
FROM ${BUILD_FROM}

ARG BUILD_ARCH=""
# Official PocketBase release, verified against the SHA-256 values published in the release's
# checksums.txt. Change all three together with scripts/bump-pocketbase.sh <version>.
ARG POCKETBASE_VERSION=0.40.4
ARG POCKETBASE_SHA256_AMD64=9042ec818570e79c3628dadcd0a756c1496d9e1173918ec409d133c02f82e5fa
ARG POCKETBASE_SHA256_ARM64=86095bf8ed9345954f0d2bf0a5fb9b57584ae60b77ebf3b6cd23a8003a3fd418

RUN set -eux; \
    arch="${BUILD_ARCH:-$(uname -m)}"; \
    case "${arch}" in \
      aarch64|arm64) pb_arch=arm64; pb_sha256="${POCKETBASE_SHA256_ARM64}" ;; \
      amd64|x86_64) pb_arch=amd64; pb_sha256="${POCKETBASE_SHA256_AMD64}" ;; \
      *) echo "unsupported arch ${arch}" >&2; exit 1 ;; \
    esac; \
    zip="pocketbase_${POCKETBASE_VERSION}_linux_${pb_arch}.zip"; \
    curl -fsSL -o "/tmp/${zip}" "https://github.com/pocketbase/pocketbase/releases/download/v${POCKETBASE_VERSION}/${zip}"; \
    echo "${pb_sha256}  /tmp/${zip}" | sha256sum -c -; \
    unzip -o "/tmp/${zip}" pocketbase -d /usr/local/bin; \
    chmod 755 /usr/local/bin/pocketbase; \
    rm -f "/tmp/${zip}"; \
    pocketbase --version

# /opt/app holds migrations, hooks, provision.sh and project.env: generated copies of the repo
# root's files, written by scripts/sync-addon.sh (never edit them here).
COPY rootfs /
COPY run.sh /run.sh
RUN chmod 755 /run.sh /opt/app/provision.sh

EXPOSE 8090
CMD [ "/run.sh" ]
