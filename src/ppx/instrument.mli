(* This file is part of Bisect_ppx, released under the MIT license. See
   LICENSE.md for details, or visit
   https://github.com/aantron/bisect_ppx/blob/master/LICENSE.md. *)



class instrumenter : object 
   inherit Ppxlib.Ast_traverse.map 
   method transform_impl_file: Ppxlib.Parsetree.structure -> Ppxlib.Parsetree.structure 
end 
(**  This class implements an instrumenter to be used through the {i -ppx}
    command-line switch. *)
