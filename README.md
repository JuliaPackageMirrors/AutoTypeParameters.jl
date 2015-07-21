[![Build Status](https://travis-ci.org/andrewcooke/AutoTypeParameters.jl.svg?branch=master)](https://travis-ci.org/andrewcooke/AutoTypeParameters.jl)


# AutoTypeParameters

A Julia library to reversibly encode "any" value so that it can be used as a
type parameter.

## Do I Need This?

You need this if you have an error like:

```
ERROR: TypeError: apply_type: in Val, expected Type{T}, got XXX
```

when you try to create a "complicated" dependent type.

That error is (partly) explained
[here](https://groups.google.com/forum/#!topic/julia-users/Ihl50vgSQxw) - it
occurs because the kinds of things that can be types in Julia is limited.
Partly for sensible reasons (you don't want a mutable type), but also because
of arbitrary implementation details.

## What Does It Do?

This package has two functions - `freeze()` and `thaw()` - that translate
arbitrary values back and forth into a form that *is* accepted by Julia.

## How Does It Work?

It's all very simple.  The `freeze()` function takes the output from
`showall()` and converts it into a Symbol, while `thaw()` uses `eval()` to
convert it back into a "real" value:

```julia
julia> using AutoTypeParameters

julia> freeze("a string")
symbol("ATP \"a string\"")

julia> thaw(eval, symbol("ATP \"a string\""))
"a string"
```

## Isn't There A Better Way?

Well, the advantage of the default approach is that the type parameter is
readable.  The disadvantage, of course, is that it requires `showall()` to
generate output that `eval()` can handle.

An alternative, which is more reliable, but less readable, is to use
`serialize()` and `deserialize()`.  You can select this with the keyword
`format`:

```julia
julia> freeze("a string"; format=:serialize)
symbol("ATP=JhWGYSBzdHJpbmc=")

julia> thaw(eval, symbol("ATP=JhWGYSBzdHJpbmc="))
"a string"
```

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
MyType{symbol("ATP \"strings not allowed\"")}(42)

julia> extract_type{N}(x::MyType{N}) = thaw(eval, N)
extract_type (generic function with 1 method)

julia> extract_type(MyType("strings not allowed", 42))
"strings not allowed"
```
