external afterAll : ((unit -> unit)[@bs ]) -> unit = "afterAll"[@@bs.val ]

let () =
  afterAll
    ((fun ()  ->
        Runtime.write_coverage_data (); 
        Runtime.reset_coverage_data ())
    [@bs ])