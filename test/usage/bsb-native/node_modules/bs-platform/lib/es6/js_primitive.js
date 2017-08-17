'use strict';


function is_nil_undef(x) {
  if (x === null) {
    return /* true */1;
  } else {
    return +(x === undefined);
  }
}

function null_undefined_to_opt(x) {
  if (x === null || x === undefined) {
    return /* None */0;
  } else {
    return /* Some */[x];
  }
}

function undefined_to_opt(x) {
  if (x === undefined) {
    return /* None */0;
  } else {
    return /* Some */[x];
  }
}

function null_to_opt(x) {
  if (x === null) {
    return /* None */0;
  } else {
    return /* Some */[x];
  }
}

function option_get(x) {
  if (x) {
    return x[0];
  } else {
    return undefined;
  }
}

function option_get_unwrap(x) {
  if (x) {
    return x[0][1];
  } else {
    return undefined;
  }
}

export {
  is_nil_undef          ,
  null_undefined_to_opt ,
  undefined_to_opt      ,
  null_to_opt           ,
  option_get            ,
  option_get_unwrap     ,
  
}
/* No side effect */
