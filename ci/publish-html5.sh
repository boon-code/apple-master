#!/bin/bash

. /opt/env.sh  # ensure environment is set

[ -d "public" ] || { echo "ERROR: missing public/ directory"; exit 1; }

rm -rf apple-master-html5/
cp -rv public apple-master-html5 \
    && butler push apple-master-html5 zahnputzmonster/apple-master-revived:html5
