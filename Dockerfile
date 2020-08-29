FROM ubuntu:focal as buildstage

ENV BUMP 20200829.1

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends install \
        build-essential \
        ca-certificates \
        cmake \
        git \
        libasio-dev \
        libboost-all-dev \
        libbz2-dev \
        liblua5.2-dev \
        libluabind-dev \
        libssl-dev \
        libstxxl-dev \
        libstxxl1v5 \
        libtbb-dev \
        libxml2-dev \
        libzip-dev \
        lua5.2 \
        pkg-config

ENV OSRM_BACKEND_VERSION v5.22.0
ENV OSRM_BACKEND_VERSION v5.22.0-customsnapping.3
RUN git clone --branch $OSRM_BACKEND_VERSION --single-branch --depth 1 https://github.com/Project-OSRM/osrm-backend.git
COPY ./osrm-gcc9.patch /osrm-backend/
RUN cd /osrm-backend && \
    patch -p1 < osrm-gcc9.patch && \
    git show --format="%H" | head -n1 > /opt/OSRM_GITSHA && \
    echo "Building OSRM gitsha $(cat /opt/OSRM_GITSHA)" && \
    mkdir -p build && \
    cd build && \
    BUILD_TYPE="Release" && \
    ENABLE_ASSERTIONS="Off" && \
    BUILD_TOOLS="Off" && \
    echo "Building ${BUILD_TYPE} with ENABLE_ASSERTIONS=${ENABLE_ASSERTIONS} BUILD_TOOLS=${BUILD_TOOLS}" && \
    cmake .. -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DENABLE_ASSERTIONS=${ENABLE_ASSERTIONS} -DBUILD_TOOLS=${BUILD_TOOLS} -DENABLE_LTO=On && \
    cmake build . && \
    cmake --build . --target install && \
    ldconfig

ENV VROOM_VERSION master
RUN git clone --depth 1 --single-branch --branch $VROOM_VERSION https://github.com/VROOM-Project/vroom.git && \
    mkdir vroom/bin && \
    cd vroom/src && \
    make && \
    cp ../bin/* /usr/local/bin && \
    ldconfig

FROM ubuntu:focal as runstage

COPY --from=buildstage /usr/local /usr/local
COPY --from=buildstage /opt /opt

RUN mkdir -p /src && \
    mkdir -p /opt && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        expat \
        git \
        gosu \
        libboost-chrono1.71.0 \
        libboost-date-time1.71.0 \
        libboost-filesystem1.71.0 \
        libboost-iostreams1.71.0 \
        libboost-program-options1.71.0 \
        libboost-regex1.71.0 \
        libboost-thread1.71.0 \
        liblua5.2-0 \
        libtbb2 \
        netcat \
        postgresql-client && \
    git clone --depth 1 https://github.com/VROOM-Project/vroom-express.git && \
    useradd -m -s /bin/bash osm && \
    useradd -m -s /bin/bash osrm && \
    useradd -m -s /bin/bash vroom && \
    mkfifo -m 600 /vroom-express/logpipe && \
    chown vroom /vroom-express/logpipe && \
    ln -sf /vroom-express/logpipe /vroom-express/access.log && \
    ln -sf /vroom-express/logpipe /vroom-express/error.log && \
    sed -ri "s/(osrm_address:).*,/\1 \"osrm-backend\",/" /vroom-express/src/index.js && \
    apt purge -y git && \
    apt autoremove --purge -y && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

RUN curl -sL https://deb.nodesource.com/setup_12.x | bash - && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN cd /vroom-express && \
    npm install

WORKDIR /vroom-express

COPY vroom-express.sh /usr/local/bin/vroom-express.sh
CMD ["vroom-express.sh"]


EXPOSE 5000
EXPOSE 3000
