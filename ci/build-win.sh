#!/bin/bash

. /opt/env.sh  # ensure environment is set

zig build -Doptimize=ReleaseSafe -Dtarget=x86_64-windows-gnu
