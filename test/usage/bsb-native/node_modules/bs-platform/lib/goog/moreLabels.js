'use strict';
goog.module("bs-platform.moreLabels");

var $$Map   = goog.require("bs-platform.map");
var $$Set   = goog.require("bs-platform.set");
var Hashtbl = goog.require("bs-platform.hashtbl");

var Hashtbl$1 = /* Hashtbl */[
  Hashtbl.create,
  Hashtbl.clear,
  Hashtbl.reset,
  Hashtbl.copy,
  Hashtbl.add,
  Hashtbl.find,
  Hashtbl.find_all,
  Hashtbl.mem,
  Hashtbl.remove,
  Hashtbl.replace,
  Hashtbl.iter,
  Hashtbl.fold,
  Hashtbl.length,
  Hashtbl.randomize,
  Hashtbl.stats,
  Hashtbl.Make,
  Hashtbl.MakeSeeded,
  Hashtbl.hash,
  Hashtbl.seeded_hash,
  Hashtbl.hash_param,
  Hashtbl.seeded_hash_param
];

var $$Map$1 = /* Map */[$$Map.Make];

var $$Set$1 = /* Set */[$$Set.Make];

exports.Hashtbl = Hashtbl$1;
exports.$$Map   = $$Map$1;
exports.$$Set   = $$Set$1;
/* Hashtbl Not a pure module */
