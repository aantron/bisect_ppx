'use strict';
goog.module("bs-platform.node_process");

var Js_dict = goog.require("bs-platform.js_dict");
var Process = goog.require("process");

function putEnvVar(key, $$var) {
  Process.env[key] = $$var;
  return /* () */0;
}

function deleteEnvVar(s) {
  return Js_dict.unsafeDeleteKey(Process.env, s);
}

exports.putEnvVar    = putEnvVar;
exports.deleteEnvVar = deleteEnvVar;
/* Js_dict Not a pure module */
