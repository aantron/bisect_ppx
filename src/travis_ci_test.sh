#!/usr/bin/env bash

export opam_pin_add=""
travis_install_on_linux () {
    # Install OCaml and OPAM PPAs
    case "$OCAML_VERSION,$OPAM_VERSION" in
        4.02,1.1.0) ppa=avsm/ocaml42+opam11 ;;
        4.02,1.2.0) ppa=avsm/ocaml42+opam12; export opam_pin_add="add" ;;
      *) echo Unknown $OCAML_VERSION,$OPAM_VERSION; exit 1 ;;
    esac

    echo "yes" | sudo add-apt-repository ppa:$ppa
    sudo apt-get update -qq

    sudo apt-get install -qq ocaml ocaml-native-compilers camlp4-extra opam time git
    sudo apt-get install libxml2-utils
}

travis_install_on_osx () {
    brew update > /dev/null
    brew install opam
    export opam_pin_add="add"
}

case $TRAVIS_OS_NAME in
  osx) travis_install_on_osx ;;
  linux) travis_install_on_linux ;;
  *) echo "Unknown $TRAVIS_OS_NAME"; exit 1
esac

export OPAMYES=1

# Set up OPAM
opam init $opam_init_options
eval `opam config env`

# Configure and view settings
echo "ocaml -version"
ocaml -version
echo "opam --version"
opam --version
echo "git --version"
git --version

# Bypass opam bug #1747
git config --global user.email "you@example.com"
git config --global user.name "Your Name"

echo
echo "Install dependencies"
echo
opam install ocamlfind ocamlbuild ppx_tools

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
opam install ounit ppx_blob ppx_deriving # Used in test suite.
export PATH=$RESTRICTED_PATH

echo
echo "Testing"
echo
make dev
make tests STRICT_DEPENDENCIES=yes
( cd tests && make performance )

echo
echo "Testing documentation generation"
echo
make doc

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
make -C tests/usage
