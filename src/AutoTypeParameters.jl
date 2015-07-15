
module AutoTypeParameters

export freeze, thaw


TAG = :ATP

function valid(x)
    try
        Val{x}
        true
    catch
        false
    end
end



if false

function freeze(x) 
    if !(typeof(x) <: Tuple && x[1] == TAG) && valid(x)
        x
    else
        buf = IOBuffer()
        showall(buf, x)
        (TAG, symbol(buf.data))
    end
end

function thaw(eval, x)
    if typeof(x) <: Tuple && x[1] == TAG
        eval(parse(string(x[2])))
    else
        x
    end
end

end



# ok, let's try the introspection approach again, but this time go via Expr

function value_to_expr(x)
    if valid((x,))
        x
    else
        Expr(:call, value_to_expr(typeof(x)), 
             map(n -> value_to_expr(getfield(x, n)), fieldnames(x))...)
    end
end

function value_to_expr(x::DataType)
    types = x.types
    if length(types) > 0
        Expr(:curly, symbol(x), map(value_to_expr, types)...)
    else
        symbol(x)
    end
end


value_to_expr(x::AbstractString) = Expr(:call, symbol(typeof(x)), 
                                        Expr(:vect, map(Uint8, collect(bytestring(x)))...))

value_to_expr(x::Vector) = Expr(:call, value_to_expr(typeof(x)), 
                                map(value_to_expr, x)...)

expr_to_sexpr(x) = x
expr_to_sexpr(x::Expr) = (x.head, map(expr_to_sexpr, x.args)...)

extract(x, symbols) = x
extract(x::Symbol, symbols) = (push!(symbols, x); ())
extract(x::Tuple, symbols) = map(y -> extract(y, symbols), x)

function extract_symbols(x)
    symbols = Symbol[]
    x = extract(x, symbols)
    (TAG, x, symbols...)
end

function freeze(x) 
    if !(typeof(x) <: Tuple && x[1] == TAG) && valid(x)
        x
    else
        extract_symbols(expr_to_sexpr(value_to_expr(x)))
    end
end


sexpr_to_expr(x) = x
sexpr_to_expr(x::Tuple) = Expr(x[1], map(sexpr_to_expr, x[2:end])...)

insert(x, symbols) = x
insert(x::Tuple, symbols) = length(x) == 0 ? pop!(symbols) : map(y -> insert(y, symbols), x)

insert_symbols(x) = insert(x[2], reverse(Symbol[x[3:end]...]))

function thaw(eval, x)
    if typeof(x) <: Tuple && x[1] == TAG
        eval(sexpr_to_expr(insert_symbols(x)))
    else
        x
    end
end









# this worked but is a lot of fuss when we can just store the symbol

if false

function value_to_expr(x)
    buf = IOBuffer()
    showall(buf, x)
    parse(UTF8String(buf.data))
end

expand_str(x) = x
expand_str(x::Expr) = Expr(x.head, map(expand_str, x.args)...)
expand_str(x::AbstractString) = Expr(:call, symbol(typeof(x)), Expr(:vect, map(Uint8, collect(bytestring(x)))...))

expr_to_sexpr(x) = x
expr_to_sexpr(x::Expr) = (x.head, map(expr_to_sexpr, x.args)...)

extract(x, symbols) = x
extract(x::Symbol, symbols) = (push!(symbols, x); ())
extract(x::Tuple, symbols) = map(y -> extract(y, symbols), x)

function extract_symbols(x)
    symbols = Symbol[]
    x = extract(x, symbols)
    (TAG, x, symbols...)
end

function freeze(x) 
    if typeof(x) != Tuple || x[1] != TAG
        try
            Val{x}
            return x
        catch TypeError
            # fall through to encoding
        end
    end
    extract_symbols(expr_to_sexpr(expand_str(value_to_expr(x))))
end


sexpr_to_expr(x) = x
sexpr_to_expr(x::Tuple) = Expr(x[1], map(sexpr_to_expr, x[2:end])...)

insert(x, symbols) = x
insert(x::Tuple, symbols) = length(x) == 0 ? pop!(symbols) : map(y -> insert(y, symbols), x)

insert_symbols(x) = insert(x[2], reverse(Symbol[x[3:end]...]))

function thaw(eval, x)
    if typeof(x) <: Tuple && x[1] == TAG
        eval(sexpr_to_expr(insert_symbols(x)))
    else
        x
    end
end

end




# this (based on introspection) really didn't work well.  there are lots of
# inconsistencies.  and it's hard to tell when a type is described completely.

# i should write a blog post on how crappy it all is at some point.

if false

# we encode everything as either:
# - a value
# - a tuple with a symbol followed by two tuples,
#   (s::Symbol, t::Tuple, v::Tuple), which is evaluated s{t...}(v...) if 
#   the t tuple is non-empty, and s(v...) if not.
# also, nested expressions are themselves expanded first
#
# HOWEVER, the above does not work, because symbols can only be at the first
# level of nesting.  so once we have the tree as described above we extract
# all the symbols, replacing them with empty tuples, and append them to the
# tuple at the "root" (there's no confusion with empty t and v values above,
# because of the regularity of the structure).
#
# inversion then requires that these symbols are re-inserted.
#
# finally, we use the raw value if possible, since it's much more readable; if
# we hve to encode, thet we add a TAG prefix to make that clear.

TAG = :ATP

tagged(x) = false
tagged(x::Tuple) = length(x) > 1 && x[1] == TAG

function valid_type_parameter(x)
    try
        Val{x}
        true
    catch
        false
    end
end


# let's start with expansion, because it follows from the comment above

thaw_(eval, x) = x

escape(x) = x
escape(x::Symbol) = QuoteNode(x)


function thaw_(eval, t::Tuple)
    head = t[1]
    args = map(x -> escape(thaw_(eval, x)), t[3])
    # need to special case arrays and tuples
    if head == :Vector
        args = (Expr(:vect, args...),)
    elseif head == :Tuple
        args = (Expr(:tuple, args...),)
    end
    if length(t[2]) > 0
        # attempt this, but it may fail if the dtype was declared without
        params = map(x -> escape(thaw_(eval, x)), t[2])
        try
            return eval(Expr(:call, Expr(:curly, head, params...),  args...))
        catch
            # fall through to ignoring type parameters
        end
    end
    eval(Expr(:call, head, args...))
end

function thaw(eval, x)
    if tagged(x)
        thaw_(eval, insert(x[2:end]))
    else
        x
    end
end


function freeze_(x; test=valid_type_parameter)
    println(x)
    if test((x,))   # test inside parens
        x
    elseif isbits(x) || x == Any
        symbol(x)
    else
        typ = typeof(x)
        types = typ.types
        names = tuple(fieldnames(typ)...)
        (symbol(typ), (map(x -> freeze_(x; test=test), types)...), map(n -> freeze_(getfield(x, n); test=test), names))
    end
end

# tuples require a tuple argument and don't have named components
# TODO - this isn't tested and looks wrong
function freeze_{T<:Tuple}(t::T; test=valid_type_parameter)
    println("tuple: $t")
    map(x -> println("type: $(typeof(x)) $(typeof(x) <: Tuple)"), t)
    tuple(:tuple, (map(x -> freeze_(x; test=test), T.types)...), map(x -> freeze_(x; test=test), t))
end

# this isn't right, but ASCIIString(Symbol) fails
# may be able to improve once have arrays?
function freeze_{S<:AbstractString}(s::S; test=valid_type_parameter)
    tuple(:string, (), (symbol(s),))
end

# arrays don't return anything via types, don't have named components, and
# take an array (not tuple) as argument, so we also need to special case thaw.
function freeze_{T}(v::Vector{T}; test=valid_type_parameter)
    tuple(:Vector, (freeze_(T; test=test),), map(x -> freeze_(x; test=test), (v...)))
end

# TODO - more freeze_() definitions for different types here...

function freeze(x; test=valid_type_parameter)
    println("---- $x")
    if test(x) && !tagged(x)
        x
    else
        (TAG, extract(freeze_(x; test=test))...)
    end
end


# extract symbols - the structure has two levels with different rules (the
# meaning of an empty tuple switches betwene levels).

# NOTE - `symbols` is mutated in the code below

EMPTY = ()

extract1(x, symbols) = x

function extract1(x::Symbol, symbols)
    push!(symbols, x)
    EMPTY
end

function extract1(t::Tuple, symbols)
    push!(symbols, t[1])
    # i can't find anywhere that says that normal function args are evaluated
    # left to right
    t2 = extract2(t[2], symbols)
    t3 = extract2(t[3], symbols)
    (EMPTY, t2, t3)
end

extract2(t::Tuple, symbols) = map(x -> extract1(x, symbols), t)


function extract(t::Tuple)
    symbols = Symbol[]
    u = extract1(t, symbols)
    tuple(u, symbols...)
end


# insert symbols - again, we need to respect the two levels.

insert1(x, symbols) = x

function insert1(t::Tuple, symbols)
    if t == EMPTY
        pop!(symbols)
    else
        t1 = pop!(symbols)
        t2 = insert2(t[2], symbols)
        t3 = insert2(t[3], symbols)
        (t1, t2, t3)
    end
end

insert2(t::Tuple, symbols) = map(x -> insert1(x, symbols), t)


function insert(t::Tuple)
    symbols = reverse(Symbol[t[2:end]...])
    insert1(t[1], symbols)
end

end

end
