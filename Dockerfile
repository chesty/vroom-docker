FROM debian:buster-slim as buildstage

ENV BUMP 2019012401
ENV VROOM_VERSION v1.3.0

RUN apt update && \
    apt install -y git \
        pkg-config && \
    git clone --depth 1 --single-branch https://github.com/Project-OSRM/osrm-backend.git

RUN cd osrm-backend && \
    apt-get update && \
    apt-get -y --no-install-recommends install cmake make git gcc g++ libbz2-dev libstxxl-dev libstxxl1v5 libxml2-dev \
    libzip-dev libboost-all-dev lua5.2 liblua5.2-dev libtbb-dev -o APT::Install-Suggests=0 -o APT::Install-Recommends=0 && \
    echo "Building OSRM ${DOCKER_TAG}" && \
    git show --format="%H" | head -n1 > /opt/OSRM_GITSHA && \
    echo "Building OSRM gitsha $(cat /opt/OSRM_GITSHA)" && \
    mkdir -p build && \
    cd build && \
    BUILD_TYPE="Release" && \
    ENABLE_ASSERTIONS="Off" && \
    BUILD_TOOLS="Off" && \
    case ${DOCKER_TAG} in *"-debug"*) BUILD_TYPE="Debug";; esac && \
    case ${DOCKER_TAG} in *"-assertions"*) BUILD_TYPE="RelWithDebInfo" && ENABLE_ASSERTIONS="On" && BUILD_TOOLS="On";; esac && \
    echo "Building ${BUILD_TYPE} with ENABLE_ASSERTIONS=${ENABLE_ASSERTIONS} BUILD_TOOLS=${BUILD_TOOLS}" && \
    cmake .. -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DENABLE_ASSERTIONS=${ENABLE_ASSERTIONS} -DBUILD_TOOLS=${BUILD_TOOLS} -DENABLE_LTO=On && \
    make install && \
    cd ../profiles && \
    cp -r * /opt && \
    \
    ldconfig && \
    git clone --depth 1 --single-branch --branch $VROOM_VERSION https://github.com/VROOM-Project/vroom.git && \
    mkdir vroom/bin && \
    cd vroom/src && \
    make && \
    rm -rf /usr/local/lib/libosrm* && \
    cp ../bin/* /usr/local/bin && \
    strip /usr/local/bin/*

FROM debian:buster-slim as runstage

COPY --from=buildstage /usr/local /usr/local
COPY --from=buildstage /opt /opt

RUN mkdir -p /src && \
    mkdir -p /opt && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        expat \
        git \
        gosu \
        libboost-chrono1.67.0 \
        libboost-date-time1.67.0 \
        libboost-filesystem1.67.0 \
        libboost-iostreams1.67.0 \
        libboost-program-options1.67.0 \
        libboost-regex1.67.0 \
        libboost-thread1.67.0 \
        liblua5.2-0 \
        libtbb2 \
        netcat \
        npm \
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
    cd /vroom-express && \
    npm install && \
    apt purge -y git && \
    apt autoremove --purge -y && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

COPY vroom-express.sh /usr/local/bin/vroom-express.sh
CMD ["vroom-express.sh"]

WORKDIR /opt

EXPOSE 5000
EXPOSE 3000
