module Swizzles

"""
    swizzle(x, indices...)
    swizzle(T, x, indices...)

Create a new object made up of `x[i₁], x[i₂], ...` where `indices = (i₁, i₂, ...)`.
If a type is provided as first argument, the result will be wrapped into it.
"""
function swizzle end

function swizzle(::Type{Tuple}, v::AbstractVector, i, indices...)
  T = typeof(v)
  indices = (i, indices...)
  ntuple(i -> v[indices[i]], length(indices))
end
swizzle(::Type{T}, v, i, indices...) where {T} = construct_swizzle(T, swizzle(Tuple, v, i, indices...))
swizzle(v::AbstractVector, i) = swizzle(eltype(v), v, i)
swizzle(v::AbstractVector, i, j, indices...) = swizzle(typeof(v), v, i, j, indices...)

construct_swizzle(::Type{T}, args::Tuple) where {T} = T(args...)
construct_swizzle(::Type{Vector}, args::Tuple) = [args...]
construct_swizzle(::Type{Vector{T}}, args::Tuple) where {T} = T[args...]

export swizzle

end
