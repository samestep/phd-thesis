# Type parameters and dispatch: the storage type is the element type of the
# vector, so only `fill` and `report` take it, but the compute type isn't the
# type of any argument, so every function in the chain takes it as one
# (`total(Float64, xs, n)`) and passes it on, and a literal like `0.1` is
# always a Float64 and has to be converted to `C`. Ranges are 1-based and
# inclusive, so `total` sums `xs[1:n]`. Julia compiles a specialized method
# for each pair of types, so `S[]` is a packed vector and nothing dispatches
# at run time.
function fill(::Type{C}, ::Type{S}, n) where {C,S}
    xs = S[]
    for _ in 1:n
        push!(xs, S(C(0.1)))
    end
    xs
end

function accumulate(::Type{C}, xs, from, to) where {C}
    sum = zero(C)
    for i in from:to
        sum += C(xs[i])
    end
    sum
end

total(::Type{C}, xs, n) where {C} = accumulate(C, xs, 1, n)

scaled(::Type{C}, xs, n) where {C} = round(Int, total(C, xs, n) * C(1000.0))

report(::Type{C}, ::Type{S}, n) where {C,S} = println(scaled(C, fill(C, S, n), n))

# Compute in f64, store in f64.
report(Float64, Float64, 1000000)
# Compute in f64, store in f32: half the memory.
report(Float64, Float32, 1000000)
# Compute in f32, store in f32.
report(Float32, Float32, 1000000)
