# Type parameters and dispatch: the storage type is the element type of the
# vector, but the compute type isn't the type of any argument, so it's passed
# as one (`report(Float64, Float32, n)`), and a literal like `0.1` is always a
# Float64 and has to be converted to `C`. Julia compiles a specialized method
# for each pair of types, so `S[]` is a packed vector and nothing dispatches
# at run time.
function report(::Type{C}, ::Type{S}, n) where {C<:AbstractFloat,S<:AbstractFloat}
    list = S[]
    for _ in 1:n
        push!(list, S(C(0.1)))
    end
    sum = zero(C)
    for x in list
        sum += C(x)
    end
    println(round(Int, sum * C(1000.0)))
end

# Compute in f64, store in f64.
report(Float64, Float64, 1000000)
# Compute in f64, store in f32: half the memory.
report(Float64, Float32, 1000000)
# Compute in f32, store in f32.
report(Float32, Float32, 1000000)
