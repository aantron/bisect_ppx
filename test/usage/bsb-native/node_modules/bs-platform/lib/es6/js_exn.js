'use strict';

import * as Caml_exceptions from "./caml_exceptions.js";

var $$Error = Caml_exceptions.create("Js_exn.Error");

function internalToOCamlException(e) {
  if (Caml_exceptions.isCamlExceptionOrOpenVariant(e)) {
    return e;
  } else {
    return [
            $$Error,
            e
          ];
  }
}

function raiseError(str) {
  throw new Error(str);
}

function raiseEvalError(str) {
  throw new EvalError(str);
}

function raiseRangeError(str) {
  throw new RangeError(str);
}

function raiseReferenceError(str) {
  throw new ReferenceError(str);
}

function raiseSyntaxError(str) {
  throw new SyntaxError(str);
}

function raiseTypeError(str) {
  throw new TypeError(str);
}

function raiseUriError(str) {
  throw new URIError(str);
}

export {
  $$Error                  ,
  internalToOCamlException ,
  raiseError               ,
  raiseEvalError           ,
  raiseRangeError          ,
  raiseReferenceError      ,
  raiseSyntaxError         ,
  raiseTypeError           ,
  raiseUriError            ,
  
}
/* No side effect */
