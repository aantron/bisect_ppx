#!/usr/bin/env bash

set -e
set -x

case $TRAVIS_OS_NAME in
    "linux") OPAM_OS=linux;;
    "osx") OPAM_OS=macos;;
    *) echo Unsupported system $TRAVIS_OS_NAME; exit 1;;
esac

OPAM_VERSION=2.0.5
OPAM_PKG=opam-${OPAM_VERSION}-x86_64-${OPAM_OS}

date

wget https://github.com/ocaml/opam/releases/download/${OPAM_VERSION}/${OPAM_PKG}
sudo mv ${OPAM_PKG} /usr/local/bin/opam
sudo chmod a+x /usr/local/bin/opam

date

opam init -y --bare --disable-sandboxing --disable-shell-hook

if [ ! -d _opam/bin ]
then
    rm -rf _opam
    opam switch create . $COMPILER $REPOSITORIES --no-install
fi

date

# Prepare environment
eval `opam config env`

# Check packages
ocaml -version
opam --version

echo
echo "Installing dependencies"
echo
opam install -y --deps-only .

date

echo
echo "Compiling"
echo
make build

date

echo
echo "Testing"
echo
make test

date

if [ "$USAGE_TEST" == YES ]
then
    echo
    echo "Testing package usage"
    echo
    # Reason has 4.08 support in master.
    opam install -y reason
    opam install -y js_of_ocaml
    make clean-usage usage
fi

if [ "$SELF_COVERAGE" == YES ]
then
    make self-coverage
    (cd _self && \
        _build/install/default/bin/meta-bisect-ppx-report \
            --coveralls ../coverage.json \
            --service-name travis-ci --service-job-id $TRAVIS_JOB_ID \
            bisect*.meta)
    curl -L -F json_file=@./coverage.json https://coveralls.io/api/v1/jobs
fi

opam clean
