
using AutoTypeParameters: freeze, thaw

using Base.Test


immutable Type1
    a
    b
end

immutable Type2{A,B}
    a::A
    b::B
end

for (value, param) in [(1, 1),
                       (Int64, Int64),
                       ((1, 2, 3), (1, 2, 3)),
                       (Type1(1, 2), (:ATP, symbol("Type1(1,2)"))),
                       ("abc", (:ATP,symbol("\"abc\""))),
                       ([1,2], (:ATP,symbol("[1,2]"))),
                       ((1, ("two", 3.0)), (:ATP,symbol("(1,(\"two\",3.0))")))]

    println("$(value) -> $(freeze(value))")

    # we can invert things correctly
    @test thaw(eval, freeze(value)) == value

    # we get what we expect
    @test freeze(value) == param

    # what we get is a valid type parameter
    @test Val{freeze(value)} == Val{param}

end
