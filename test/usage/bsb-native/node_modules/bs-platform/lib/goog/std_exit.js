'use strict';
goog.module("bs-platform.std_exit");

var Pervasives = goog.require("bs-platform.pervasives");

Pervasives.do_at_exit(/* () */0);

/*  Not a pure module */
