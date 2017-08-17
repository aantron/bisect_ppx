'use strict';
goog.module("bs-platform.caml_backtrace");

var Caml_builtin_exceptions = goog.require("bs-platform.caml_builtin_exceptions");

function caml_convert_raw_backtrace_slot() {
  throw [
        Caml_builtin_exceptions.failure,
        "caml_convert_raw_backtrace_slot unimplemented"
      ];
}

exports.caml_convert_raw_backtrace_slot = caml_convert_raw_backtrace_slot;
/* No side effect */
