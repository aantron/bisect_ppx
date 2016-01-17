PP=`ocamlfind query ppx_blob`
ocamlc.opt -c -I ../../_build -I $PP -ppx $PP/ppx_blob -ppx ../../_build/src/syntax/bisect_ppx.byte -dsource expr_blob.ml
