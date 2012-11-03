(*
 * This file is part of Bisect.
 * Copyright (C) 2008-2012 Xavier Clerc.
 *
 * Bisect is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * Bisect is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *)

type error =
  | Parsing_error of string
  | Invalid_operands of string
  | Invalid_function_parameters of string
  | Unknown_function of string
  | Invalid_result_kind
  | Evaluation_error of string
  | Invalid_path of string

let string_of_error = function
  | Parsing_error s ->
      Printf.sprintf "parsing error (%S)" s
  | Invalid_operands op ->
      Printf.sprintf "invalid operands for operator %S" op
  | Invalid_function_parameters fn ->
      Printf.sprintf "invalid parameters for function %S" fn
  | Unknown_function fn ->
      Printf.sprintf "unknown function %S" fn
  | Invalid_result_kind ->
      "evaluation result is not a data set"
  | Evaluation_error s ->
      Printf.sprintf "evaluation error (%S)" s
  | Invalid_path p ->
      Printf.sprintf "invalid path %S" p

exception Exception of error

let fail err =
  raise (Exception err)


type expr_val =
  | Integer_val of int
  | Simple_data of (string, int array) Hashtbl.t
  | Multiple_data of (string, int array) Hashtbl.t list

let parse s =
  let lexbuf = Lexing.from_string s in
  try
    CombineParser.start CombineLexer.token lexbuf
  with
  | Failure s ->
      fail (Parsing_error s)
  | e ->
      raise e

let get_dir_contents path dir =
  try
    let elems = Array.to_list (Sys.readdir path) in
    List.filter
      (fun e ->
        try
          Sys.is_directory (Filename.concat path e) = dir
        with _ -> false)
      elems
  with _ ->
    []

type path_element = Exact of string | Pattern of Str.regexp

let compile_regexp s =
  let rewrite s =
    let buff = Buffer.create 128 in
    String.iter
      (function
        | '*' -> Buffer.add_string buff ".*"
        | '?' -> Buffer.add_char buff '.'
        | ch -> Buffer.add_char buff ch)
      s;
    Buffer.contents buff in
  if (String.contains s '*') || (String.contains s '?') then
    Pattern (Str.regexp (rewrite s))
  else
    Exact s

let decompose_path f =
  let rec decomp f =
    let d = Filename.dirname f in
    let b = Filename.basename f in
    let special_dir =
      List.mem
        d
        [Filename.current_dir_name; Filename.parent_dir_name; Filename.dir_sep] in
    if special_dir then
      (compile_regexp b) :: (compile_regexp d) :: []
    else
      (compile_regexp b) :: (decomp d) in
  match decomp f with
  | hd :: tl -> hd, List.rev tl
  | [] -> fail (Invalid_path f)

let get_file_list f =
  let f =
    if Filename.is_relative f then
      Filename.concat (Sys.getcwd ()) f
    else
      f in
  let file, dirs = decompose_path f in
  let rec build_list prefixes elements =
    match elements with
    | (Exact hd) :: tl ->
        let prefixes =
          List.map
            (fun prefix -> Filename.concat prefix hd)
            prefixes in
        build_list prefixes tl
    | (Pattern hd) :: tl ->
        let prefixes =
          List.map
            (fun prefix ->
              let elems = get_dir_contents prefix true in
              let elems =
                List.filter
                  (fun elem ->
                    (Str.string_match hd elem 0)
                      && ((Str.match_end ()) = (String.length elem)))
                  elems in
              List.map (fun elem -> Filename.concat prefix elem) elems)
            prefixes in
        let prefixes = List.concat prefixes in
        build_list prefixes tl
    | [] -> prefixes in
  let dirs = build_list [""] dirs in
  match file with
  | Exact f ->
      List.map
        (fun dir -> Filename.concat dir f)
        dirs
  | Pattern p ->
      let files =
        List.map
          (fun dir ->
            let elems = get_dir_contents dir false in
            let elems =
              List.filter
                (fun elem ->
                  (Str.string_match p elem 0)
                    && ((Str.match_end ()) = (String.length elem)))
                elems in
            List.map (fun elem -> Filename.concat dir elem) elems)
          dirs in
      List.concat files

let read_runtime_data_from_file file =
  let res = Hashtbl.create 17 in
  List.iter
    (fun (k, arr) ->
      Hashtbl.replace res k arr)
    (Common.read_runtime_data file);
  res

let read_runtime_data_from_pattern patt =
  let files = get_file_list patt in
  List.map (fun f -> read_runtime_data_from_file f) files

let (//) x y =
  if y = 0 then fail (Evaluation_error "division by zero")
  else x / y

let rec eval_expr expr =
  let open ReportUtils in
  let open CombineAST in
  let combine_data_data op d1 d2 =
    let res = Hashtbl.copy d1 in
    Hashtbl.iter
      (fun k arr ->
        let arr' = try op (Hashtbl.find res k) arr with Not_found -> arr in
        Hashtbl.replace res k arr')
      d2;
    res in
  let combine_data_function f d =
    let res = Hashtbl.copy d in
    Hashtbl.iter
      (fun _ arr ->
        let len = Array.length arr in
        for i = 0 to pred len do
          arr.(i) <- f arr.(i)
        done)
      res;
    res in
  match expr with
  | Binop ((Plus | Minus) as op, e1, e2) ->
      let op_simple, op_integer, op_repr = match op with
      | Plus -> combine_data_data (+|), (++), "+"
      | Minus -> combine_data_data (-|), (--), "-"
      | _ -> assert false in
      (match eval_expr e1, eval_expr e2 with
      | (Simple_data d1), (Simple_data d2) -> Simple_data (op_simple d1 d2)
      | (Integer_val i1), (Integer_val i2) -> Integer_val (op_integer i1 i2)
      | _ -> fail (Invalid_operands op_repr))
  | Binop ((Multiply | Divide) as op, e1, e2) ->
      let op_simple, op_integer, op_repr = match op with
      | Multiply -> (fun i -> combine_data_function (fun x -> i * x)), ( * ), "*"
      | Divide -> (fun i -> combine_data_function (fun x -> i // x)), (//), "/"
      | _ -> assert false in
      (match eval_expr e1, eval_expr e2 with
      | (Integer_val i), (Simple_data d)
      | (Simple_data d), (Integer_val i) -> Simple_data (op_simple i d)
      | (Integer_val i1), (Integer_val i2) -> Integer_val (op_integer i1 i2)
      | _ -> fail (Invalid_operands op_repr))
  | Function (fn, el) ->
      let el = List.map eval_expr el in
      (match fn with
      | "sum" | "fold" ->
          (match el with
          | [Multiple_data l] ->
              let res =
                List.fold_left
                  (fun acc elem ->
                    combine_data_data (+|) acc elem)
                  (Hashtbl.create 17)
                  l in
              Simple_data res
          | _ -> fail (Invalid_function_parameters fn))
      | "notnull" ->
          (match el with
          | [Simple_data d] ->
              let res = Hashtbl.copy d in
              Hashtbl.iter
                (fun _ arr ->
                  let len = Array.length arr in
                  for i = 0 to pred len do
                    if arr.(i) != 0 then arr.(i) <- 1
                  done)
                res;
              Simple_data res
          | _ -> fail (Invalid_function_parameters fn))
      | _ -> fail (Unknown_function fn))
  | File file -> Simple_data (read_runtime_data_from_file file)
  | Files patt -> Multiple_data (read_runtime_data_from_pattern patt)
  | Integer x -> Integer_val x

let eval s =
  let expr =
    try
      parse s
    with
    | (Exception _) as e -> raise e
    | (Failure s) -> fail (Parsing_error s)
    | e -> fail (Parsing_error (Printexc.to_string e)) in
  try
    eval_expr expr
  with
  | (Exception _) as e -> raise e
  | e -> fail (Evaluation_error (Printexc.to_string e))

let eval s =
  match eval s with
  | Simple_data x -> x
  | _ -> fail Invalid_result_kind
