
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

function freeze_show(x)
    buf = IOBuffer()
    write(buf, ATP_PREFIX)
    write(buf, SHOW_PREFIX)
    showall(buf, x)
    symbol(buf.data)
end

@compat function thaw_show(eval, x::AbstractString)
    eval(parse(x))
end

function notv3()
    if VERSION < v"0.4-"
        error("Serialization (base64) not supported in v0.3")
    end
end

function freeze_serialize(x)
    notv3()
    buf = IOBuffer()
    serialize(buf, x)
    symbol(string(ATP_PREFIX, SERIALIZE_PREFIX, base64encode(buf.data)))
end

@compat function thaw_serialize(eval, x::AbstractString)
    notv3()
    deserialize(IOBuffer(base64decode(x)))
end
 
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
