#!/bin/bash

. /opt/env.sh  # ensure environment is set

zig build -Doptimize=ReleaseSmall -Dtarget=wasm32-emscripten --sysroot /opt/emsdk/upstream/emscripten \
 && mkdir -p public \
 && cp -v zig-out/htmlout/* public/ \
 && mv public/index.html public/full.html \
 && cp -v html/* public/
