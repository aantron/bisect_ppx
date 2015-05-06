PP=`ocamlfind query ppx_getenv`
ocamlc.opt -c -I ../../_build -I $PP -ppx $PP/ppx_getenv -ppx ../../_build/src/syntax/bisect_ppx.byte -dsource expr_env.ml
