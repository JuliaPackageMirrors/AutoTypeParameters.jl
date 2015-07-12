
module AutoTypeParameters

export freeze, thaw, TAG


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
    # need to special case arrays
    if t[1] == :Vector
        args = (Expr(:vect, args...),)
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
