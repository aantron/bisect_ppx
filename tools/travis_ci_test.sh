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
    sudo apt-get install liblapack-dev
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

echo
echo "Compiling"
echo
make all

opam install ounit ppx_blob ppx_deriving # Used in test suite.
echo
echo "Testing"
echo
make tests STRICT_DEPENDENCIES=yes
( cd tests && make performance )
