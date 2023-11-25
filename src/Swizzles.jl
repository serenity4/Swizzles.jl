module Swizzles

"""
    swizzle(v, indices...)
    swizzle(T, v, indices...)

Create a new object made up of `v[i₁], v[i₂], ...` where `indices = (i₁, i₂, ...)`.
If a type is provided as first argument, the result will be wrapped into it via [`construct_swizzle`](@ref).

A default type is derived from `swizzle(v, indices...)`, where a single index infers `T = eltype(v)`, and multiple indices infer `T = typeof(v)`.
For statically sized vectors (`StaticVector` and `SizedVector`), an extension extends [StaticArraysCore](https://github.com/JuliaArrays/StaticArraysCore.jl) vectors such that one of correct size is used to hold the result.

See also: [`swizzle!`](@ref)
"""
function swizzle end

function swizzle(::Type{Tuple}, v, i, indices...)
  indices = (i, indices...)
  ntuple(i -> v[indices[i]], length(indices))
end
swizzle(::Type{T}, v, i, indices...) where {T} = construct_swizzle(T, swizzle(Tuple, v, i, indices...))
swizzle(v::AbstractVector, i) = swizzle(eltype(v), v, i)
swizzle(v::AbstractVector, i, j, indices...) = swizzle(typeof(v), v, i, j, indices...)

"""
    construct_swizzle(T, args)

Wrap the result of a swizzling operation into `T(args...)`.

This method may be extended for your own types, e.g. if a different constructor must be used.

See also: [`swizzle`](@ref)
"""
function construct_swizzle end

construct_swizzle(::Type{T}, args::Tuple) where {T} = T(args...)
construct_swizzle(::Type{Vector}, args::Tuple) = [args...]
construct_swizzle(::Type{Vector{T}}, args::Tuple) where {T} = T[args...]

"""
    swizzle!(v, value, indices...)

Mutate `v` at `indices` such that `v[i₁] = value[1], v[i₂] = value[2], ...` where `indices = (i₁, i₂, ...)`.
and return `value`.

If any indices are duplicated in `indices`, `v` will be consecutively overwritten at the corresponding index, retaining the last value per the semantics of `setindex!`.
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

Base.showerror(io::IO, exc::InvalidSwizzle) = print(io, "InvalidSwizzle: ", exc.msg)

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

"""
    @swizzle v.xyz
    @swizzle v.rgb
    @swizzle T v.xyz
    @swizzle v.xyz = [1, 2, 3]
    @swizzle v.rgb = v.bgr

Perform a swizzling operation, extracting components or, if an assignment is provided, mutating them.

This macro translates a `.<field1><field2>...<fieldn>` syntax such as `.xwyz` into an appropriate call to [`swizzle`](@ref) (non-mutating) or [`swizzle!`](@ref) (mutating).

If the operation is non-mutating, an additional type argument `T` may be provided to put the result of the extraction into a specific type (see the documentation for [`swizzle`](@ref) for more details).

Each letter on the right-hand side of `.` is considered as a separate component name, and is by default mapped to:
- `x` or `r` -> first component
- `y` or `g` -> second component
- `z` or `b` -> third component
- `w` or `a` -> fourth component

using nomenclature from geometry processing (`[x, y, z, w]` representing spatial coordinates) and computer graphics (`[r, g, b, a]` representing color vectors).

This mapping may be customized from Julia 1.11 onwards (see extended help).

# Extended help

From Julia 1.11 onwards, [scoped values](https://docs.julialang.org/en/v1.11-dev/base/scopedvalues/) allow the customization of this component mapping, via `@with Swizzles.component_names => Dict(...)`. For example, if you wanted to consider width, height and depth as first, second and third components, you may do
```julia
new_names = Dict('w' => 1, 'h' => 2, 'd' => 3)
# You might also have done `@with Swizzles.component_names => new_names`
# to discard existing names.
@with Swizzles.component_names => merge(Swizzles.component_names, new_names) do
  @swizzle dims.w
  @swizzle dims.whd
end
```
For convenience, you could even define your own `@swizzle` macro shadowing the one exported by this package as
```julia
using Swizzles

macro _swizzle(ex)
  new_names = Dict('w' => 1, 'h' => 2, 'd' => 3)
  ex = quote
    @with Swizzles.component_names => merge(Swizzles.component_names[], \$new_names) do
      Swizzles.@swizzle \$ex
    end
  end
  esc(ex)
end
```

Whether or not this is a good idea is for you to decide.
"""
macro swizzle end

macro swizzle(T, ex)
  generate_swizzle_expr(ex, T)
end

macro swizzle(ex)
  generate_swizzle_expr(ex)
end

export swizzle, swizzle!, @swizzle

end
