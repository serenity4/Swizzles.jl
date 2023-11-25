module Swizzles

"""
    swizzle(v, indices...)
    swizzle(T, v, indices...)

Create a new object made up of `v[i₁], v[i₂], ...` where `indices = (i₁, i₂, ...)`.
If a type is provided as first argument, the result will be wrapped into it.
"""
function swizzle end

function swizzle(::Type{Tuple}, v, i, indices...)
  indices = (i, indices...)
  ntuple(i -> v[indices[i]], length(indices))
end
swizzle(::Type{T}, v, i, indices...) where {T} = construct_swizzle(T, swizzle(Tuple, v, i, indices...))
swizzle(v::AbstractVector, i) = swizzle(eltype(v), v, i)
swizzle(v::AbstractVector, i, j, indices...) = swizzle(typeof(v), v, i, j, indices...)

construct_swizzle(::Type{T}, args::Tuple) where {T} = T(args...)
construct_swizzle(::Type{Vector}, args::Tuple) = [args...]
construct_swizzle(::Type{Vector{T}}, args::Tuple) where {T} = T[args...]

"""
    swizzle!(v, value, indices...)

Mutate `v` at `indices` such that `v[i₁] = value[1], v[i₂] = value[2], ...` where `indices = (i₁, i₂, ...)`,
and return `value`.
"""
function swizzle!(v, value, i, indices...)
  indices = (i, indices...)
  for (i, ind) in enumerate(indices)
    v[ind] = value[i]
  end
  value
end

struct InvalidSwizzle <: Exception
  msg::String
end

Base.showerror(io::IO, exc::InvalidSwizzle) = print(io, "InvalidSwizzle: ", msg)

component_names_dict = Dict(
  # [x, y, z, w] denoting a spatial 4-vector in homogeneous space.
  'x' => 1,
  'y' => 2,
  'z' => 3,
  'w' => 4,

  # [r, g, b, a] denoting a color 4-vector with an alpha component.
  'r' => 1,
  'g' => 2,
  'b' => 3,
  'a' => 4,
)

if @isdefined(ScopedValue)
  component_names = ScopedValue(component_names_dict)
else
  component_names = Ref(component_names_dict)
end

function generate_swizzle_expr(ex::Expr, T = nothing)
  lhs, rhs = Meta.isexpr(ex, :(=), 2) ? ex.args : (ex, nothing)
  !isnothing(rhs) && !isnothing(T) && throw(ArgumentError("A type argument can't be provided for a mutating swizzle operation in `$ex"))
  if !Meta.isexpr(lhs, :., 2)
    throw(ArgumentError("Expected swizzle expression of the form `<v>.<swizzle>`, got `$lhs`"))
  end
  v, swizzle = lhs.args
  if !isa(swizzle, QuoteNode)
    throw(InvalidSwizzle("Expected `QuoteNode` value in `swizzle`, got value of type `$(typeof(swizzle))"))
  end
  swizzle = swizzle.value
  if !isa(swizzle, Symbol)
    throw(InvalidSwizzle("Expected symbol `QuoteNode` value in `swizzle`, got value of type `$(typeof(swizzle))"))
  end
  components = [component_names[][c] for c in string(swizzle)]
  f = isnothing(rhs) ? :swizzle : :swizzle!
  args = [esc(v); components]
  !isnothing(T) && pushfirst!(args, esc(T))
  !isnothing(rhs) && insert!(args, 2, esc(rhs))
  :($f($(args...)))
end

macro swizzle(T, ex)
  generate_swizzle_expr(ex, T)
end

macro swizzle(ex)
  generate_swizzle_expr(ex)
end

export swizzle, swizzle!, @swizzle

end
