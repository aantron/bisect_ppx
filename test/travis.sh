#!/usr/bin/env bash

if [ "$BUCKLESCRIPT" = YES ]
then
    bash ./test/travis-bucklescript.sh
else
    bash ./test/travis-opam.sh
fi
