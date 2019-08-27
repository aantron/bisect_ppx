#!/usr/bin/env bash

set -e
set -x

if [ "$TRAVIS_EVENT_TYPE" == cron ]
then
    rm -rf ~/.opam
    rm -rf ./_opam
    rm -rf ~/.esy
    rm -rf ./test/bucklescript/node_modules
    rm -rf ./node_modules
    rm -rf ./_cache
fi

if [ "$BUCKLESCRIPT" = YES ]
then
    bash ./test/ci/travis-bucklescript.sh
else
    bash ./test/ci/travis-opam.sh
fi
