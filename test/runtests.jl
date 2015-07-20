
using AutoTypeParameters: freeze, thaw

using Base.Test
using AutoHashEquals


immutable Type1
    a
    b
end

@auto_hash_equals immutable Type2{A,B}
    a::A
    b::B
end


for (value, param) in [(1, 1),
                       (Int64, Int64),
                       ((1, 2, 3), (1, 2, 3)),
                       (Type1(1, 2), symbol("ATP Type1(1,2)")),
                       ("abc", symbol("ATP \"abc\"")),
                       ([1,2], symbol("ATP [1,2]")),
                       ((1, ("two", 3.0)), symbol("ATP (1,(\"two\",3.0))")),
                       (Type2{String,Int}("a", 1), symbol("ATP Type2{AbstractString,Int64}(\"a\",1)"))]

    for format in (:show, :serialize)

        println("$(format): $(value) -> $(freeze(value; format=format))")

        # we can invert things correctly
        @test thaw(eval, freeze(value; format=format)) == value
        
        # what we get is a valid type parameter
        @test Val{freeze(value)} == Val{param}

        if format == :show
            # we get what we expect
            @test freeze(value) == param
        end
        
    end
    
end

