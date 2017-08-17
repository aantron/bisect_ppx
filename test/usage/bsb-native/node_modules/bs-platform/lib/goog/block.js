'use strict';
goog.module("bs-platform.block");


function __(tag, block) {
  block.tag = tag;
  return block;
}

exports.__ = __;
/* No side effect */
