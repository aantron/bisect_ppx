#!/usr/bin/env bash

set -e
set -x

npm --version

date

WD=`pwd`
if [ ! -f node_modules/.bin/esy ]
then
    npm install --no-save esy
    export PATH="$WD/node_modules/.bin:$PATH"
else
    mkdir -p _wrapped_esy
    ln -s $WD/node_modules/.bin/esy-solve-cudf _wrapped_esy/esy-solve-cudf
    cp test/ci/travis-wrapped-esy.sh _wrapped_esy/esy
    chmod a+x _wrapped_esy/esy
    export PATH="$WD/_wrapped_esy:$PATH"
fi

date

make -C test/bucklescript install

date

make -C test/bucklescript test

date

make -C test/bucklescript clean-for-caching

date
