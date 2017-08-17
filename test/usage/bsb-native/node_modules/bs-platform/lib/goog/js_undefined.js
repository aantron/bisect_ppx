'use strict';
goog.module("bs-platform.js_undefined");


function bind(x, f) {
  if (x !== undefined) {
    return f(x);
  } else {
    return undefined;
  }
}

function iter(x, f) {
  if (x !== undefined) {
    return f(x);
  } else {
    return /* () */0;
  }
}

function from_opt(x) {
  if (x) {
    return x[0];
  } else {
    return undefined;
  }
}

exports.bind     = bind;
exports.iter     = iter;
exports.from_opt = from_opt;
/* No side effect */
