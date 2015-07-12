
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
                       (Type1(1, 2), (:ATP,((),(),1,2),:call,:Type1)),
                       ("abc", (:ATP,((),(),((),0x61,0x62,0x63)),:call,:ASCIIString,:vect)),
                       ([1,2], (:ATP,((),1,2),:vect)),
                       ((1, ("two", 3.0)), (:ATP,((),1,((),((),(),((),0x74,0x77,0x6f)),3.0)),:tuple,:tuple,:call,:ASCIIString,:vect))]

    println("$(value) -> $(freeze(value))")

    # we can invert things correctly
    @test thaw(eval, freeze(value)) == value

    # we get what we expect
    @test freeze(value) == param

    # what we get is a valid type parameter
    @test Val{freeze(value)} == Val{param}

end
