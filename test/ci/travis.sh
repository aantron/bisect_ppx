#!/usr/bin/env bash

if [ "$BUCKLESCRIPT" = YES ]
then
    bash ./test/ci/travis-bucklescript.sh
else
    bash ./test/ci/travis-opam.sh
fi
