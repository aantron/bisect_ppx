#!/usr/bin/env bash

set -e
set -x

npm --version

date

WD=`pwd`
export PATH="$WD/node_modules/.bin:$PATH"
if [ ! -f node_modules/.bin/esy ]
then
    npm install --no-save esy
fi

date

make -C test/bucklescript install

date

make -C test/bucklescript test

date

make -C test/bucklescript clean-for-caching

date
