[![Build Status](https://travis-ci.org/andrewcooke/AutoTypeParameters.jl.svg?branch=master)](https://travis-ci.org/andrewcooke/AutoTypeParameters.jl)


# AutoTypeParameters

A Julia library to reversibly encode "any" value so that it can be used as a
type parameter.

## Do I Need This?

You need this if you have an error like:

```
ERROR: TypeError: apply_type: in Val, expected Type{T}, got ASCIIString
```

when you try to create a "complicated" depedent type.

That error is (partly) explained
[here](https://groups.google.com/forum/#!topic/julia-users/Ihl50vgSQxw) - it
occurs because the kinds of things that can be types in Julia is limited.
Partly for sensible reasons (you don't want a mutable type), but also because
of arbitrary implementation details.

## What Does It Do?

This package has two functions - `freeze()` and `thaw()` - that translate
arbitrary values back and forth into a form that *is* accepeted by Julia.

## How Does It Work?

It's all very simple.  The `freeze()` function takes the output from `print()`
and converts it into a Symbol, while `thaw()` uses `eval()` to convert it back
into a "real" value.

## Isn't There A Better Way?

It seems like cheating, right?

Explaining why it works this way needs a little history.

Originally, this package had some quite complex code that used introspection
to create an expression that evaluated to give the value being encoded.  That
expression was then encoded in nested tuples, with low-level values and
symbols.

But the introspection features in Julia are something of a mess.  Or I'm dumb.
Or perhaps a bit of both.

When I took a step back, and looked at my code, I realised that it was doing
seomthing pretty similar to the
[`parse`](https://julia.readthedocs.org/en/latest/manual/metaprogramming/)
function.  Which meant that I could avoid a lot of complex, error-prone code
by using `parse()` instead.

But `parse()` requires a string as input.  So I used `showall()` to generate a
string from the value, parsed that, and encoded it as before.

This worked and was very cool.

But it was also completely pointless.  I might as well just take the string
and convert it directly to a Symbol.  It stores equivalent information with
much less processing.

So that's how things work now.

## Warning

Because this package uses `eval()` it should not be passed arbitrary values
from an untrusted user.

## Example

```julia
julia> using AutoTypeParameters

julia> type MyType{N}
           x
       end

julia> MyType{"strings not allowed"}(42)
ERROR: TypeError: apply_type: in MyType, expected Type{T}, got ASCIIString

julia> MyType(N, x) = MyType{freeze(N)}(x)
MyType{N}

julia> MyType("strings not allowed", 42)
MyType{(:ATP,symbol("\"strings not allowed\""))}(42)

julia> extract_type{N}(x::MyType{N}) = thaw(eval, N)
extract_type (generic function with 1 method)

julia> extract_type(MyType("strings not allowed", 42))
"strings not allowed"
```
