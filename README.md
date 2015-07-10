[![Build Status](https://travis-ci.org/andrewcooke/AutoTypeParameters.jl.svg?branch=master)](https://travis-ci.org/andrewcooke/AutoTypeParameters.jl)


# AutoTypeParameters

A Julia library to reversibly encode "any" value so that it can be used as a
type parameter.

The core functions are:

* `freeze(x)` which returns an encoding of `x` suitable for use as a type
  parameter.

* `thaw(eval, x)` which decodes a type parameter `x`.  The
  [`eval`](https://julia.readthedocs.org/en/latest/stdlib/base/?highlight=eval#Base.eval)
  function should be from the module where encoding occurred (or, at least,
  contain bindings for any symbols required during decoding - eg. names of
  types that occur inside `x`).

## Warnings

1. Under development and incomplete.  A particularly big gap is the lack of
   support for arrays.

1. "Normal" uses of Julia should not require this library.  Most likely, you
   should not need this.

1. Neither `freeze()` nor `thaw()` are efficient.

1. The encoded value is rather long and hard to read.
