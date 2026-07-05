FROM debian:trixie-slim AS build
ENV VER_TAG=SQUID_7_6
COPY build-squid.sh .
RUN ./build-squid.sh

FROM debian:trixie-slim
COPY --from=build /opt/squid /opt/squid
RUN apt-get update && \
    apt-get -y --no-install-recommends install git ca-certificates curl && \
    apt-get -y install $(apt-cache depends -q -i squid | awk '$1 ~ /^Depends:/{print $2}' | grep -v squid) && \
    cat <<EOF >>/opt/squid/etc/squid.conf
logfile_rotate 0
cache_log stdio:/dev/tty
access_log stdio:/dev/tty
cache_store_log stdio:/dev/tty
pid_filename /tmp/squid.pid
EOF

USER proxy
CMD ["/opt/squid/sbin/squid", "-N", "-Y", "-C"]
