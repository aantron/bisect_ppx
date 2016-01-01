PPD=`ocamlfind query ppx_deriving`
ocamlc -c -I $PPD -ppx "$PPD/ppx_deriving $PPD/ppx_deriving_show.cma" -dsource expr_deriving.ml 2> expr_deriving_part2.ml
ocamlc -c -I ../../_build -ppx ../../_build/src/syntax/bisect_ppx.byte -dsource expr_deriving_part2.ml
