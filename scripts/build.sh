#!/usr/bin/env bash

if [[ -d bld ]]; then
    rm -rf bld
fi
mkdir bld
cd bld
cmake .. && make
