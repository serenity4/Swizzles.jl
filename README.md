# Swizzles

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://serenity4.github.io/Swizzles.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://serenity4.github.io/Swizzles.jl/dev/)
[![Build Status](https://github.com/serenity4/Swizzles.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/serenity4/Swizzles.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/serenity4/Swizzles.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/serenity4/Swizzles.jl)

Lightweight package meant to provide functionality and syntax for [swizzling](https://en.wikipedia.org/wiki/Swizzling_(computer_graphics)) operations.

Swizzling is defined for any linearly indexable object, the main example of which are `AbstractVector`.

```julia
julia> using Swizzles

julia> v = [10, 20, 30, 40];

julia> swizzle(v, 3, 1)
2-element Vector{Int64}:
 30
 10
```

Besides extracting vector components, swizzling may be used for mutation, with `swizzle!`:

```julia
julia> v = [10, 20, 30, 40];

julia> swizzle!(v, [1, 2], 4, 2)
2-element Vector{Int64}:
 1
 2

julia> v
4-element Vector{Int64}:
 10
  2
 30
  1
```

Additionally, a `@swizzle` macro is defined which provides nice syntax for it:

```
julia> v = [10, 20, 30, 40];

julia> @swizzle v.xy
2-element Vector{Int64}:
 10
 20

julia> @swizzle v.rgb
3-element Vector{Int64}:
 10
 20
 30

julia> @swizzle v.xyx
3-element Vector{Int64}:
 10
 20
 10

julia> @swizzle v.wx = [1, 2]
2-element Vector{Int64}:
 1
 2

julia> v
4-element Vector{Int64}:
  2
 20
 30
  1
```

See the [documentation](https://serenity4.github.io/Swizzles.jl/dev/) to know more about the motivation for this functionality and a complete reference beyond what was shown here.
