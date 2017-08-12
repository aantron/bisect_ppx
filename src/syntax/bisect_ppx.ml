(* This Source Code Form is subject to the terms of the Mozilla Public License,
   v. 2.0. If a copy of the MPL was not distributed with this file, You can
   obtain one at http://mozilla.org/MPL/2.0/. *)



include Ppx_bisect
(* Ppx_bisect is a side-effecting module. In particular, it registers the
   bisect_ppx PPX with the driver. *)

let () = Migrate_parsetree.Driver.run_main ()
