# Type parameters and dispatch, with DoubleFloats.jl's `Double64`. `sd`
# follows the type of the vector it is given, as generic Julia does, so
# its accumulators are written `zero(T)` rather than `0.0`; but nothing
# passed to `readings` or `report` has the type, so they take it as an
# argument (`readings(T)`) and everything above them has to pass it on.
# Every literal is built in `T`, `T(100000002) / 10`, because
# `10000000.2` is a Float64 and only promotes to `Double64` after it has
# been rounded (the third line would then print 100000001); and a buffer
# made with `zeros(n)` in a helper stays Float64 and silently rounds every
# `Double64` stored in it. Julia compiles a specialized
# method per type, so nothing dispatches at run time. Julia's scoped
# precision, `setprecision(BigFloat, 106) do ... end`, reaches every
# callee but only `BigFloat`s: around this code as written for Float64 it
# changes nothing.
using DoubleFloats

# NIST StRD NumAcc4: 10000000.2, then 10000000.1 and 10000000.3 in turn.
function readings(::Type{T}) where {T}
    xs = [T(100000002) / 10]
    for i in 1:1000
        push!(xs, isodd(i) ? T(100000001) / 10 : T(100000003) / 10)
    end
    xs
end

# The schoolbook one-pass formula, as PostgreSQL's `stddev` computed it
# until version 12, clamp included.
function sd(xs::AbstractVector{T}) where {T}
    n = zero(T)
    sum = zero(T)
    sum_sq = zero(T)
    for x in xs
        n += 1
        sum += x
        sum_sq += x * x
    end
    numerator = n * sum_sq - sum * sum
    numerator <= 0 ? zero(T) : sqrt(numerator / (n * (n - 1)))
end

show_sd(sd) = println(round(Int, sd * 1000000000))

report(::Type{T}) where {T} = show_sd(sd(readings(T)))

report(Float64)
xs = readings(Float64)
show_sd(sd(Double64.(xs)))
report(Double64)
