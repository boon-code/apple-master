FROM ubuntu:latest

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
 && DEBIAN_FRONTEND=noninteractive \
    apt-get install -y \
        ca-certificates \
        curl \
        vim \
        tar \
        xz-utils \
 && rm -rf /var/lib/apt/lists/*

ENV ZIG_VERSION 0.11.0

RUN curl -o /tmp/zig-${ZIG_VERSION}.tar.xz "https://ziglang.org/download/${ZIG_VERSION}/zig-linux-x86_64-${ZIG_VERSION}.tar.xz" \
 && cd /tmp \
 && tar xf zig-${ZIG_VERSION}.tar.xz \
 && cp -r "/tmp/zig-linux-x86_64-${ZIG_VERSION}" /opt/zig \
 && rm -r /tmp/zig*

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
 && DEBIAN_FRONTEND=noninteractive \
    apt-get install -y \
        git \
        python3 \
 && rm -rf /var/lib/apt/lists/*

RUN cd /opt \
 && git clone https://github.com/emscripten-core/emsdk.git --depth=1 \
 && cd emsdk \
 && ./emsdk install latest \
 && ./emsdk activate latest

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
 && DEBIAN_FRONTEND=noninteractive \
    apt-get install -y \
        libx11-dev \
        libglvnd-dev \
        libxcursor-dev \
        libxrandr-dev \
        libxinerama-dev \
        libxi-dev \
 && rm -rf /var/lib/apt/lists/*

COPY env.sh /opt/env.sh
RUN chmod a+x /opt/env.sh

RUN echo 'source /opt/env.sh' >> /etc/bash.bashrc

# Based on these guides:
# - https://emscripten.org/docs/getting_started/downloads.html
# - https://github.com/raysan5/raylib/wiki/Working-for-Web-(HTML5)
