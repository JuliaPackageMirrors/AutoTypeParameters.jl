
"""
Reversibly encode 'any' value so that it can be used as a type parameter.

`freeze(V)` converts V to a form that can be used as a type parameter.

`thaw(eval, P)` converts a type parameter P back to the original value.

Two approaches are available, using either `showall()` and `eval()` (the
default), or (in v0.4 onwards) `serialize()` and `deserialize()`.  The first
gives more readable results.

Examples:
```
julia> freeze([1,2])
Symbol("ATP [1,2]")

julia> freeze([1,2]; format=:serialize)
symbol("ATP=FQAJgAEAAAAAAAAAAgAAAAAAAAA=") 

julia> thaw(eval, Symbol("ATP [1,2]"))
2-element Array{Int64,1}:
 1
 2

julia> thaw(eval, symbol("ATP=FQAJgAEAAAAAAAAAAgAAAAAAAAA="))
2-element Array{Int64,1}:
 1
 2
```
"""

module AutoTypeParameters

using Compat

export freeze, thaw


const ATP_PREFIX = "ATP"
const SHOW_PREFIX = " "
const SERIALIZE_PREFIX = "="


function valid(x)
    try
        @compat Val{x}
        true
    catch
        false
    end
end

@compat function starts_with(s::AbstractString, p)
    length(s) >= length(p) && s[1:length(p)] == p
end
starts_with(s, p) = starts_with(string(s), p)

@compat drop(s::AbstractString, p) = s[length(p)+1:end]

"Convert to type parameter using showall()."
function freeze_show(x)
    buf = IOBuffer()
    write(buf, ATP_PREFIX)
    write(buf, SHOW_PREFIX)
    showall(buf, x)
    symbol(buf.data)
end

"Convert from showall() style type parameter."
@compat function thaw_show(eval, x::AbstractString)
    eval(parse(x))
end

function notv3()
    if VERSION < v"0.4-"
        error("Serialization (base64) not supported in v0.3")
    end
end

"Convert to type parameter using serialize()."
function freeze_serialize(x)
    notv3()
    buf = IOBuffer()
    serialize(buf, x)
    symbol(string(ATP_PREFIX, SERIALIZE_PREFIX, base64encode(buf.data)))
end

"Comvert from serialize() stype type parameter."
@compat function thaw_serialize(eval, x::AbstractString)
    notv3()
    deserialize(IOBuffer(base64decode(x)))
end
 
"""
`freeze(V)`

Convert a value to a form that can be used as a type parameter.

By default, constructs a symbol based on `showall()`.  When
`format=:serialize`, constructs a symbol using base64 encoding on the output
of `serialize()`.

The original value can be retrieved using `thaw()`.
"""
function freeze(x; format=:show)
    if valid(x) && !(isa(x, Symbol) && starts_with(x, ATP_PREFIX))
        x
    elseif format == :show
        freeze_show(x)
    elseif format == :serialize
        freeze_serialize(x)
    else
        error("Unexpected format for freeze: $(format)")
    end
end

"""
`thaw(eval, P)`

Retrieve the value stored in a type parameter using `freeze()`.

The first argument should be `eval` from the current scope (it is only
used with showall style parameters).
"""
function thaw(eval, x)
    if !isa(x, Symbol) || !starts_with(x, ATP_PREFIX)
        x
    else
        s = drop(string(x), ATP_PREFIX)
        if starts_with(s, SERIALIZE_PREFIX)
            thaw_serialize(eval, drop(s, SERIALIZE_PREFIX))
        elseif starts_with(s, SHOW_PREFIX)
            thaw_show(eval, drop(s, SHOW_PREFIX))
        else
            error("Unexpected format for thaw: $x")
        end
    end
end

end
