
using AutoTypeParameters: extract, insert, freeze, thaw

using Base.Test


for (mixed, separate) in [(1, 1),
                          ((:a, (), (1, 2)), (((), (), (1, 2)), :a)),
                          ((:a, (), (:p, :q)), (((), (), ((), ())), :a, :p, :q))]

    println("$mixed -> $(extract(mixed))")

    @test extract(mixed) == separate

    @test Val{extract(mixed)} == Val{separate}

    @test insert(extract(mixed)) == mixed

end


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
                       (Type1(1, 2), (:ATP, ((),(),(1,2)),:Type1)),
                       ("abc", (:ATP, ((),(),((),)),:string,:abc))]

    println("$(value) -> $(freeze(value))")

    # we get what we expect
    @test freeze(value) == param

    # what we get is a valid type parameter
    @test Val{freeze(value)} == Val{param}

    # we can invert things correctly
    @test thaw(eval, freeze(value)) == value

end
