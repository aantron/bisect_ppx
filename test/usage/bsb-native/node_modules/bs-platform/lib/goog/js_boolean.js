'use strict';
goog.module("bs-platform.js_boolean");


function to_js_boolean(b) {
  if (b) {
    return true;
  } else {
    return false;
  }
}

exports.to_js_boolean = to_js_boolean;
/* No side effect */
