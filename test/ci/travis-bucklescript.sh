#!/usr/bin/env bash

set -e
set -x

date

npm --version
npm install --no-save esy
WD=`pwd`
export PATH="$WD/node_modules/.bin:$PATH"

date

make -C test/bucklescript install

date

make -C test/bucklescript test

date

make -C test/bucklescript clean-for-caching

date
