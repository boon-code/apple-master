#!/bin/bash

. /opt/env.sh  # ensure environment is set

[ -e "zig-out/bin/apple-master" ] || { echo "ERROR: missing binary to upload"; exit 1; }

butler push zig-out/bin/apple-master zahnputzmonster/apple-master-revived:linux
