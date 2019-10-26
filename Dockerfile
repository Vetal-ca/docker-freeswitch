MAINTAINER "Vitali Khlebko vitali.khlebko@vetal.ca"
FROM debian:buster as build

ENV FS_VERSION=v1.10
ENV FS_TAG=v1.10.1

# This prevents us from get errors during apt-get installs as it notifies the
# environment that it is a non-interactive one.
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update &&\
    apt-get install -y wget git-core autoconf libtool-bin build-essential lsb-release &&\
    wget -O - https://files.freeswitch.org/repo/deb/debian-release/fsstretch-archive-keyring.asc | apt-key add - &&\
    echo "deb http://files.freeswitch.org/repo/deb/debian-release/ `lsb_release -sc` main" > /etc/apt/sources.list.d/freeswitch.list &&\
    echo "deb-src http://files.freeswitch.org/repo/deb/debian-release/ `lsb_release -sc` main" >> /etc/apt/sources.list.d/freeswitch.list &&\
    apt update &&\
    apt-get build-dep -y freeswitch

# https://freeswitch.org/confluence/display/FREESWITCH/Debian+8+Jessie#Debian8Jessie-BuildingFromSource
ADD *.patch /tmp/

RUN cd /tmp  &&\
    git clone -b ${FS_VERSION} https://github.com/signalwire/freeswitch.git freeswitch &&\
    cd freeswitch &&\
    git checkout ${FS_TAG} &&\
    git config pull.rebase true &&\
    git apply /tmp/signalwire-disabled.patch &&\
    ./bootstrap.sh -j
RUN    cd /tmp/freeswitch && ./configure --enable-portable-binary \
         --prefix=/usr --localstatedir=/var --sysconfdir=/etc \
         --with-gnu-ld --with-openssl \
         --enable-core-odbc-support --enable-zrtp \
         --enable-core-pgsql-support
RUN    cd /tmp/freeswitch &&  make && make install


FROM debian:buster
ENV DEBIAN_FRONTEND noninteractive
RUN apt update && apt-get install -y unixodbc libssl-dev sqlite libfreetype6 libcurl4-openssl-dev \
    libspeex1 libspeexdsp1 libedit2 libtpl0
#RUN apk update && apk add libpq libuuid sqlite-dev curl-dev pcre-dev speex-dev speexdsp-dev libedit-dev unixodbc-dev \
#    jpeg-dev opus-dev tiff-dev libsndfile-dev lua5.2-dev ldns-dev

#COPY --from=build /etc/freeswitch /etc/freeswitch
COPY --from=build /run/freeswitch /run/freeswitch

COPY --from=build ["/usr/bin/freeswitch", "/usr/bin/fs_cli", "/usr/bin/fs_encode", "/usr/bin/fs_ivrd", \
    "/usr/bin/fsxs", "/usr/bin/gentls_cert", "/usr/bin/fs_tts", "/usr/bin/tone2wav", "/usr/bin/"]

COPY --from=build /usr/include/freeswitch /usr/include/freeswitch
COPY --from=build /usr/lib/freeswitch /usr/lib/freeswitch
COPY --from=build /usr/lib/libfreeswitch.* /usr/lib/
COPY --from=build /usr/lib/pkgconfig/freeswitch.pc /usr/lib/pkgconfig/
COPY --from=build /usr/share/freeswitch /usr/share/freeswitch
#COPY --from=build /var/lib/freeswitch /var/lib/freeswitch
COPY --from=build /var/log/freeswitch /var/log/freeswitch

ENTRYPOINT ["/usr/bin/freeswitch"]
