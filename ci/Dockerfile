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

RUN echo -e '\nPATH="${PATH}:/opt/zig"\nsource /opt/emsdk/emsdk_env.sh' >> /etc/bash.bashrc

# Continue here:
# - https://emscripten.org/docs/getting_started/downloads.html
# - https://github.com/raysan5/raylib/wiki/Working-for-Web-(HTML5)

# #Get the emsdk repo
# git clone https://github.com/emscripten-core/emsdk.git
#
# # Enter that directory
# cd emsdk
#
# # Fetch the latest version of the emsdk (not needed the first time you clone)
# git pull
# 
# # Download and install the latest SDK tools.
# ./emsdk install latest
#
# # or some specific version
# #./emsdk install 1.38.45
# 
# # Make the "latest" SDK "active" for the current user. (writes .emscripten file)
# ./emsdk activate latest
# 
# # Activate PATH and other environment variables in the current terminal
# source ./emsdk_env.sh
