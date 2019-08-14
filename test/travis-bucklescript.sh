#!/usr/bin/env bash

set -e
set -x

npm --version
npm install -g esy

make -C test/bucklescript full-test
