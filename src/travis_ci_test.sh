#!/usr/bin/env bash

set -e
set -x

travis_install_on_linux () {
    # Install OCaml and OPAM PPA
    sudo add-apt-repository -y ppa:avsm/ocaml42+opam12
    sudo apt-get update -qq

    sudo apt-get install -qq opam time git

    case "$OCAML_VERSION" in
        4.02)
            sudo apt-get install -qq ocaml-nox camlp4-extra
            opam init -y ;;
        4.03)
            opam init -y --compiler=4.03.0 ;;
        4.04)
            opam init -y --compiler=4.04.0 ;;
        *)
            echo Unknown $OCAML_VERSION
            exit 1 ;;
    esac
}

travis_install_on_osx () {
    brew update > /dev/null
    brew install opam

    case "$OCAML_VERSION" in
        4.02)
            opam init -y --compiler=4.02.3 ;;
        4.03)
            opam init -y --compiler=4.03.0 ;;
        4.04)
            opam init -y --compiler=4.04.0 ;;
        *)
            echo Unknown $OCAML_VERSION
            exit 1 ;;
    esac
}

case $TRAVIS_OS_NAME in
  osx) travis_install_on_osx ;;
  linux) travis_install_on_linux ;;
  *) echo "Unknown $TRAVIS_OS_NAME"; exit 1
esac

# Prepare environment
eval `opam config env`

# Check packages
ocaml -version | grep $OCAML_VERSION
opam --version
git --version

echo
echo "Install dependencies"
echo
opam install -y ocamlfind ocamlbuild ppx_tools cppo

GENERAL_PATH=$PATH
RESTRICTED_PATH=$PATH

if [ "$BYTECODE_ONLY" = yes ]
then
  echo
  echo "Shadowing ocamlopt"
  echo
  mkdir ocamlopt-shadow
  echo "#! /bin/bash" > ocamlopt-shadow/ocamlopt.opt
  echo "exit 2" >> ocamlopt-shadow/ocamlopt.opt
  chmod +x ocamlopt-shadow/ocamlopt.opt
  cp ocamlopt-shadow/ocamlopt.opt ocamlopt-shadow/ocamlopt
  RESTRICTED_PATH=`pwd`/ocamlopt-shadow:$PATH
  export PATH=$RESTRICTED_PATH
  which ocamlopt.opt
  which ocamlopt
fi

echo
echo "Compiling"
echo
make build

export PATH=$GENERAL_PATH
opam install -y ounit ppx_blob ppx_deriving # Used in test suite.
export PATH=$RESTRICTED_PATH

echo
echo "Testing"
echo
make dev
make tests STRICT_DEPENDENCIES=yes
make -C tests performance

echo
echo "Testing documentation generation"
echo
make doc

echo
echo "Checking OPAM file"
echo
opam lint opam

echo
echo "Testing installation"
echo
make clean
opam pin add -yn .
opam install -yt bisect_ppx
opam remove -y bisect_ppx
opam install -y bisect_ppx
ocamlfind query bisect_ppx bisect_ppx.runtime bisect_ppx.fast
which bisect-ppx-report

echo
echo "Testing package usage and Ocamlbuild plugin"
echo
make -C tests usage

if [ "$COVERALLS" = yes ]
then
  echo
  echo "Submitting coverage report"
  echo
  export PATH=$GENERAL_PATH
  opam install -y ocveralls
  make dev tests
  make -C tests coverage
  ocveralls --prefix _build.instrumented tests/_coverage/meta*.out --send
  export PATH=$RESTRICTED_PATH
fi
