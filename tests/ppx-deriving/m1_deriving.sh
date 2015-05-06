PPD=`ocamlfind query ppx_deriving`
ocamlc.opt -c -I ../../_build -I $PPD -ppx "$PPD/ppx_deriving $PPD/ppx_deriving_show.cma" -ppx ../../_build/src/syntax/bisect_ppx.byte -dsource expr_deriving.ml
