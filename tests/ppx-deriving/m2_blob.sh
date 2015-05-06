PP=`ocamlfind query ppx_blob`
ocamlc.opt -c -I ../../_build -dsource -I $PP -ppx $PP/ppx_blob -dsource expr_blob.ml 2> expr_blob_part2.ml
ocamlc.opt -c -I ../../_build -dsource -ppx ../../_build/src/syntax/bisect_ppx.byte -dsource expr_blob_part2.ml
