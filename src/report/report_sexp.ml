
let make () =
  object (self)
    method header = ""
    method footer = ""
    method summary _ = ""
    (*      Printf.sprintf "(percent %s)(total %d)" (self#sum s) s.Report_utils.total *)
    method file_header f = Printf.sprintf "(coverage-info %S '(" f
    method file_footer _ = "))\n"
    method file_summary s = Printf.sprintf "(percent %S)" (self#sum s)
    method point offset count = Printf.sprintf "(%d %d)" offset count
    method private sum s =
      let numbers x y =
        if y > 0 then
          let p = ((float_of_int x) *. 100.) /. (float_of_int y) in
          Printf.sprintf "%.2f%% covered" p
        else
          "no"
      in
      Report_utils.(numbers s.visited s.total)
  end
