[![Build Status](https://travis-ci.org/andrewcooke/AutoTypeParameters.jl.svg?branch=master)](https://travis-ci.org/andrewcooke/AutoTypeParameters.jl)


# AutoTypeParameters

A Julia library to encode "any" value so that it can be used as a type
parameter.

The two core functions are:

* `freeze(x)` which returns an encoding of `x` suitable for use as a type
  parameter.

* `thaw(eval, x)` which deocdes a type parameter `x`.  The `eval` function
  should be from module where encoding occurred (or, at least, contain
  bindings for any symbols required during decoding - eg. names of types that
  occur inside `x`).

## Warnings

1. Under development and incomplete.  A particularly big gap is a lack of
   support for arrays.

1. Most "normal" uses of Julia should not require this library.  Most likely,
   unless you an something of an expert Julia user, you should not need this.

1. Neither `freeze()` nor `thaw()` are efficient.
