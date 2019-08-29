#!/usr/bin/env bash

set -e
set -x

mkdir -p _cache

date

case $TRAVIS_OS_NAME in
    "linux") OPAM_OS=linux;;
    "osx") OPAM_OS=macos;;
    *) echo Unsupported system $TRAVIS_OS_NAME; exit 1;;
esac

OPAM_VERSION=2.0.5
OPAM_PKG=opam-${OPAM_VERSION}-x86_64-${OPAM_OS}

if [ ! -f _cache/opam ]
then
    wget https://github.com/ocaml/opam/releases/download/${OPAM_VERSION}/${OPAM_PKG}
    mv ${OPAM_PKG} _cache/opam
fi

sudo cp _cache/opam /usr/local/bin/opam
sudo chmod a+x /usr/local/bin/opam

date

opam init -y --bare --disable-sandboxing --disable-shell-hook

OPAM_FROM_CACHE=YES

if [ ! -d _opam/bin ]
then
    OPAM_FROM_CACHE=NO
    rm -rf _opam
    opam switch create . $COMPILER $REPOSITORIES --no-install
fi

date

# Prepare environment
eval `opam config env`

# Check packages
ocaml -version
opam --version

date

if [ "$OPAM_FROM_CACHE" == NO ]
then
    opam install -y --deps-only .
fi

date

if [ -d _cache/_build ]
then
    cp -r _cache/_build .
fi

make build

date

(unset TRAVIS && unset TRAVIS_JOB_ID && make test)

if [ ! -d _cache/_build ]
then
    cp -r _build _cache
fi

date

if [ "$USAGE_TEST" == YES ]
then
    opam install -y reason
    opam install -y js_of_ocaml
    make clean-usage usage
fi

if [ "$SELF_COVERAGE" == YES ]
then
    (unset TRAVIS && unset TRAVIS_JOB_ID && make self-coverage)
    (cd _self && \
        _build/install/default/bin/meta-bisect-ppx-report \
            send-to Coveralls bisect*.meta)
fi

opam clean
