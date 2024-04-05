#!/bin/bash

. /opt/env.sh  # ensure environment is set

zig build -Doptimize=ReleaseSmall -Dtarget=wasm32-emscripten --sysroot /opt/emsdk/upstream/emscripten \
 && mkdir -p public \
 && cp zig-out/htmlout/* public/
