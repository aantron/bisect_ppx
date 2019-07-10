#!/usr/bin/env bash

set -e
set -x

travis_install_on_linux () {
    wget https://github.com/ocaml/opam/releases/download/2.0.4/opam-2.0.4-x86_64-linux
    sudo mv opam-2.0.4-x86_64-linux /usr/local/bin/opam
    sudo chmod a+x /usr/local/bin/opam
}

travis_install_on_osx () {
    brew update > /dev/null
    # See https://github.com/Homebrew/homebrew-core/issues/26358.
    brew upgrade python > /dev/null
    brew install opam
}

case $TRAVIS_OS_NAME in
    osx) travis_install_on_osx ;;
    linux) travis_install_on_linux ;;
    *) echo "Unknown $TRAVIS_OS_NAME"; exit 1
esac

opam init -y --bare --disable-sandboxing --disable-shell-hook
opam switch create . $COMPILER $REPOSITORIES --no-install

# Prepare environment
eval `opam config env`

# Check packages
ocaml -version
opam --version

echo
echo "Install dependencies"
echo
opam install -y ocamlfind ocamlbuild ocaml-migrate-parsetree ppx_tools_versioned

echo
echo "Compiling"
echo
make build

opam install -y ounit
# opam install -y ppx_blob ppx_deriving

echo
echo "Testing"
echo
make test

echo
echo "Testing package usage and Ocamlbuild plugin"
echo
make usage

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
