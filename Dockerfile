FROM debian:unstable-slim

RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  autoconf \
  automake \
  bison \
  build-essential \
  ca-certificates \
  cmake \
  curl \
  flex \
  gdb \
  git \
  libboost-serialization-dev \
  libboost-test-dev \
  libboost-thread-dev \
  libcgal-dev \
  libcunit1-dev \
  libgmp-dev \
  libjson-c-dev \
  libmpfr-dev \
  libpcre3-dev \
  libprotobuf-c-dev \
  libreadline-dev \
  libsfcgal-dev \
  libtool \
  libxml2-dev \
  libxml2-utils \
  pkg-config \
  protobuf-c-compiler \
  sudo \
  valgrind \
  wget \
  xsltproc \
  zlib1g-dev && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

WORKDIR /src

ARG BUILD_THREADS=4
ARG BUILD_DATE
ENV PGDATA=/var/lib/postgresql

RUN useradd postgres && \
    mkdir -p ${PGDATA} && chown postgres ${PGDATA} && \
    mkdir -p /src/postgis && chown postgres /src/postgis
   
ENV PATH="/usr/local/pgsql/bin:${PATH}"

ARG GDAL_BRANCH=trunk
RUN git clone --depth 1 --branch ${GDAL_BRANCH} https://github.com/OSGeo/gdal && \
    cd gdal/gdal && \
    ./autogen.sh && ./configure && make -j${BUILD_THREADS} && make install && \
    cd /src && rm -rf gdal

ARG GEOS_BRANCH=master
RUN git clone --depth 1 --branch ${GEOS_BRANCH} https://github.com/libgeos/geos && \
    cd geos && \
    ./autogen.sh && ./configure && make -j${BUILD_THREADS} && make install && \
    cd /src && rm -rf geos

ARG POSTGRES_BRANCH=master
RUN git clone --depth 1 --branch ${POSTGRES_BRANCH} https://github.com/postgres/postgres && \
    cd postgres && \
    ./configure && make -j${BUILD_THREADS} && make install && \
    cd /src && rm -rf postgres

ARG PROJ_BRANCH=master
RUN git clone --depth 1 --branch ${PROJ_BRANCH} https://github.com/OSGEO/proj.4 && \
    cd proj.4 && \
    ./autogen.sh && ./configure && make -j${BUILD_THREADS} && make install && \
    cd /src && rm -rf proj.4

WORKDIR /src/postgis

RUN ldconfig /usr/local/pgsql/lib
USER postgres

# create cluster now to save time on build
RUN /usr/local/pgsql/bin/initdb -D /var/lib/postgresql
