#!/usr/bin/env bash

set -e
set -x

date

npm --version
npm install -g esy

date

make -C test/bucklescript install

date

make -C test/bucklescript test

date
