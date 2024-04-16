#!/bin/bash

. /opt/env.sh  # ensure environment is set

[ -e "zig-out/bin/apple-master.exe" ] || { echo "ERROR: missing binary to upload"; exit 1; }

butler push zig-out/bin/apple-master.exe zahnputzmonster/apple-master-revived:win
