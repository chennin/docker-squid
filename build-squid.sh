#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
sed -e "s/Types: deb/Types: deb deb-src/" -i /etc/apt/sources.list.d/debian.sources && \
apt-get update && \
apt-get -y --no-install-recommends install ca-certificates wget dirmngr libtool-bin && \
apt-get -y build-dep squid-openssl

export CXXFLAGS="-O2 -s -march=x86-64-v3 -mtune=generic -pipe -fno-omit-frame-pointer -mno-omit-leaf-frame-pointer -flto=auto -ffat-lto-objects -fstack-protector-strong -fstack-clash-protection -Wformat -Werror=format-security -fcf-protection -Wno-error=deprecated-declarations"
export CFLAGS="$CXXFLAGS"
export CPPFLAGS="-Wdate-time -D_FORTIFY_SOURCE=3"
export LDFLAGS="-Wl,-Bsymbolic-functions -flto=auto -ffat-lto-objects -Wl,-z,relro -Wl,-z,now"

# https://github.com/squid-cache/squid/releases/download/SQUID_7_6/squid-7.6.tar.xz
pkgver=$(echo ${VER_TAG} | sed -e 's/SQUID_//' -e 's/_/./')
wget -q https://github.com/squid-cache/squid/releases/download/${VER_TAG}/squid-$pkgver.tar.xz && \
mkdir squid && tar --strip-components=1 -C squid -xf squid-$pkgver.tar.xz && \
cd squid && \
./configure \
     --prefix=/opt/squid \
     --enable-auth \
     --enable-auth-basic \
     --enable-auth-ntlm \
     --enable-auth-digest \
     --enable-auth-negotiate \
     --enable-removal-policies="lru,heap" \
     --enable-storeio="aufs,ufs,diskd,rock" \
     --enable-delay-pools \
     --enable-arp-acl \
     --with-openssl \
     --enable-snmp \
     --enable-linux-netfilter \
     --enable-ident-lookups \
     --enable-useragent-log \
     --enable-cache-digests \
     --enable-referer-log \
     --enable-arp-acl \
     --enable-htcp \
     --enable-carp \
     --enable-epoll \
     --with-large-files \
     --enable-arp-acl \
     --with-default-user=proxy \
     --enable-async-io \
     --enable-truncate \
     --enable-icap-client \
     --enable-ssl-crtd \
     --disable-arch-native \
     --disable-strict-error-checking \
     --enable-wccpv2
make -j $(( $(nproc) / 2 + 1)) && \
make install
