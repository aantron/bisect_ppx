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

wget https://github.com/ocaml/opam/releases/download/${OPAM_VERSION}/${OPAM_PKG}
sudo mv ${OPAM_PKG} /usr/local/bin/opam
sudo chmod a+x /usr/local/bin/opam

opam init -y --bare --disable-sandboxing --disable-shell-hook

if [ ! -d _opam/bin ]
then
    rm -rf _opam
    opam switch create . $COMPILER $REPOSITORIES --no-install
fi

# Prepare environment
eval `opam config env`

# Check packages
ocaml -version
opam --version

echo
echo "Install dependencies"
echo
opam pin add -y --no-action bisect_ppx .
opam install -y --deps-only bisect_ppx
opam install -y ocamlbuild

echo
echo "Compiling"
echo
make build

echo
echo "Testing"
echo
make test

echo
echo "Testing package usage and Ocamlbuild plugin"
echo
make clean-usage usage

echo
echo "Testing installation"
echo
make clean
opam pin add -yn bisect_ppx .
opam install -y bisect_ppx
ocamlfind query bisect_ppx bisect_ppx.runtime
which bisect-ppx-report
opam pin add -yn bisect_ppx-ocamlbuild .
opam install -y bisect_ppx-ocamlbuild
ocamlfind query bisect_ppx-ocamlbuild
