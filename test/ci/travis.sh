#!/usr/bin/env bash

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
    RESULT=$?
    make -C test/bucklescript clean-for-caching
    exit $RESULT
else
    bash ./test/ci/travis-opam.sh
    RESULT=$?
    opam clean
    exit $RESULT
fi
