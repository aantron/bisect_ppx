PP=`ocamlfind query ppx_getenv`
ocamlc.opt -c -I ../../_build -dsource -I $PP -ppx $PP/ppx_getenv -dsource expr_env.ml 2> expr_env_part2.ml
ocamlc.opt -c -I ../../_build -dsource -ppx ../../_build/src/syntax/bisect_ppx.byte -dsource expr_env_part2.ml
