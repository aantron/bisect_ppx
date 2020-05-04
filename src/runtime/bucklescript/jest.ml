(* If we make a curried binding of `afterAll`, BuckleScript will compiles it like this:
  ```
    afterAll((function (param) { // <-- notice the `param` parameter here
      // ... snip ...
    }));
  ```
  this will cause timeout error in Jest because Jest will wait until you manully call `done` from `param`. *)
external afterAll : ((unit -> unit)[@bs ]) -> unit = "afterAll"[@@bs.val ]

let () =
  afterAll
    ((fun ()  ->
        Runtime.write_coverage_data (); 
        Runtime.reset_coverage_data ())
    [@bs ])