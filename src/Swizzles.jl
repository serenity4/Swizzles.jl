module Swizzles

using PrecompileTools

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

const component_names_dict = Dict(
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

if isdefined(Base, :ScopedValue)
  const component_names = Base.ScopedValue(component_names_dict)
else
  const component_names = Ref(component_names_dict)
end

walk(ex::Expr, inner, outer) = outer(Meta.isexpr(ex, :$) ? ex.args[1] : Expr(ex.head, map(inner, ex.args)...))
walk(ex, inner, outer) = outer(ex)

postwalk(f, ex) = walk(ex, x -> postwalk(f, x), f)
prewalk(f, ex) = walk(f(ex), x -> prewalk(f, x), identity)

generate_swizzle_expr(ex::Expr, T = nothing) = prewalk(x -> _generate_swizzle_expr(x, T), ex)
function _generate_swizzle_expr(ex, T = nothing)
  !isa(ex, Expr) && return ex
  lhs, rhs = Meta.isexpr(ex, :(=), 2) ? ex.args : (ex, nothing)
  !Meta.isexpr(lhs, :., 2) && return ex
  v, swizzle = lhs.args
  if !isa(swizzle, QuoteNode)
    throw(InvalidSwizzle("Expected `QuoteNode` value in `swizzle`, got value of type `$(typeof(swizzle))"))
  end
  swizzle = swizzle.value
  if !isa(swizzle, Symbol)
    throw(InvalidSwizzle("Expected symbol `QuoteNode` value in `swizzle`, got value of type `$(typeof(swizzle))"))
  end
  components = Any[component_names[][c] for c in string(swizzle)]
  f = isnothing(rhs) ? @__MODULE__().swizzle : swizzle!
  args = components
  pushfirst!(args, v)
  isnothing(rhs) && !isnothing(T) && pushfirst!(args, T)
  !isnothing(rhs) && insert!(args, 2, rhs)
  :($f($(args...)))
end

"""
    @swizzle v.xyz
    @swizzle v.rgb
    @swizzle T v.xyz
    @swizzle \$(v[].some.expression()).xyz
    @swizzle v.xyz = [1, 2, 3]
    @swizzle v.rgb = v.bgr
    @swizzle begin
      a.yz = b.xz
      b.w = a.x
    end

Perform a swizzling operation, extracting components or, if an assignment is provided, mutating them.

This macro translates **every** `.<field1><field2>...<fieldn>` field access syntax (e.g. `.xwyz`) in the provided expression into an appropriate call to [`swizzle`](@ref) (non-mutating) or [`swizzle!`](@ref) (mutating). To prevent this transformation from affecting part of the expression, shield the subexpression with `\$` like so: `@swizzle \$(object.vector).xyz`.

An additional type argument `T` may be provided to put the result of a non-mutating swizzle extraction into a specific type (see the documentation for [`swizzle`](@ref) for more details). It has no effect on mutating swizzles.

Each letter on the right-hand side of any `.` is considered as a separate component name, and is by default mapped to:
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

# You might also have done `@with Swizzles.component_names[] => new_names`
# to discard existing names.
@with Swizzles.component_names => merge(Swizzles.component_names[], new_names) begin
  # Note: the `@eval` is important here.
  # It prevents `@swizzle` from being executed before the scoped value is set.
  @eval begin
    @swizzle [10, 20, 30].w
    @swizzle [10, 20, 30].whd
  end
  # `@swizzle` macrocalls in `include`d files will also be affected.
  include("file.jl")
end
```
For convenience, you could even define your own `@swizzle` macro shadowing the one exported by this package as
```julia
using Swizzles

macro _swizzle(ex)
  new_names = Dict('w' => 1, 'h' => 2, 'd' => 3)
  swizzle_ex = @with Swizzles.component_names => merge(Swizzles.component_names[], new_names) begin
    # One might also pass around a `T` parameter as second argument.
    Swizzles.generate_swizzle_expr(ex)
  end
  esc(swizzle_ex)
end

@_swizzle [10, 20, 30].hd
```

Whether or not this is a good idea is for you to decide.
"""
macro swizzle end

macro swizzle(T, ex)
  esc(generate_swizzle_expr(ex, T))
end

macro swizzle(ex)
  esc(generate_swizzle_expr(ex))
end

export swizzle, swizzle!, @swizzle

@compile_workload begin
  v = [1, 2, 3, 4]
  @swizzle begin
    v.x = v.y
    v.rgb = v.zyx
    v.w = $(copy(v)).z
  end
  @swizzle Float64 (v.x, v.y + 1, v.z)
end

end
