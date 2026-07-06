#!/bin/bash
export CONT_LATEST="${REGISTRY}/${IMAGE}"
export DEBIAN_FRONTEND=noninteractive
export STORAGE_DRIVER=vfs
export BUILDAH_ISOLATION=chroot

# Release name: v7.6
# Tag name: SQUID_7_6
# squid -v: 7.6-VCS / 7.6
cd $(dirname "$0")
sudo apt-get update && sudo apt-get -y --no-install-recommends install ca-certificates curl buildah netavark jq && \
VERS=$(curl -sLfm5 https://api.github.com/repos/squid-cache/squid/releases/latest | jq -r .tag_name) && \
buildah --storage-driver "$STORAGE_DRIVER" --isolation "$BUILDAH_ISOLATION" bud -t "$CONT_LATEST" --pull=missing \
        --label VERSION_SQUID="$VERS" \
        --build-arg VER_TAG=${VERS} -f Dockerfile && \
buildah --storage-driver "$STORAGE_DRIVER" from --pull=never --name version-checker "$CONT_LATEST" && \
APP_VER=$(buildah --storage-driver "$STORAGE_DRIVER" --isolation "$BUILDAH_ISOLATION" run version-checker /opt/squid/sbin/squid -v | awk '$3 ~ /Version/{print $4}') && \
CONT_VER="${APP_VER}" && \
CONT_WITH_VER="${CONT_LATEST%%:*}:${CONT_VER//[+~]/_}" && \
echo "Container version: ${CONT_WITH_VER}" && \
echo "${REGISTRY_PACKAGE_RW}" | buildah login --password-stdin -u "${ACTOR}" "${REGISTRY}" && \
for i in "$CONT_WITH_VER"; do
  buildah --storage-driver "$STORAGE_DRIVER" tag "$CONT_LATEST" "$i" && \
  buildah --storage-driver "$STORAGE_DRIVER" push "$i"
done && \
buildah --storage-driver "$STORAGE_DRIVER" push "${CONT_LATEST}" && \
buildah --storage-driver "$STORAGE_DRIVER" images
