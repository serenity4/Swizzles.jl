#=

# Tutorial

Hello there! If you are curious about what swizzling can do and how to do it with this package, you are at the right place.

First, make sure that the package is installed and loaded, and let us create a vector to swizzle:

=#

using Swizzles

v4 = [10, 20, 30, 40]

#=

The most common use of swizzling would be to extract part of a vector. Say `v4` represents a position in [homogeneous coordinates](https://en.wikipedia.org/wiki/Homogeneous_coordinates), and we'd like to get the euclidean part. We would select the first three components, then divide by the fourth:

=#

p = v4[1:3]/v4[4]

# But we can do it in a way that is slightly more readable by using named accessors, like so:

p = @swizzle(v4.xyz)/@swizzle(v4.w)

# This is the most basic usage of swizzling. More advanced usage would include swizzling for modifying part of a vector, or reorder components. For that, we'll use colors to better keep track of components.

using Colors

v4 = [RGB(1.0, 0.0, 0.0), RGB(0.0, 1.0, 0.0), RGB(0.0, 0.0, 1.0), RGB(0.5, 0.5, 0.5)]

# It so happens that swizzling is often used in context where vectors represent color components, where `[x, y, z, w]` represent the `[r, g, b, a]` color channels. Therefore, we decided to support color-based component names by default, such that one can do

p = @swizzle v4.rgb

# You'll have noted that the various components of `p` are not actual color channels, so there is a clear abuse of language here. A single channel would have to be a single number, not a 3-channel `RGB` color value. Now, let's for example reverse the order of the first three components:

@swizzle p.rgb = p.bgr
p

# This could have been achieved with `p[1:3] = p[3:-1:1]` (or even `reverse(p)`, but that's cheating) which is still quite readable. However, swizzling syntax shines when the indexing patterns are not so linear. As `p` no longer holds actual red, green and blue data in order, we'll use spatial accessors to reduce confusion.

@swizzle p.xz = p.zx
p

# There we got back our original vector!

@swizzle v4.rga = v4.bar
v4

# Compare this to what would be done without the syntax:

## This allocates!

p[[1, 3]] = p[[3, 1]]
v4[[1, 2, 4]] = v4[[3, 4, 1]]

## This is just more verbose (though arguably clearer for certain situations;
## less does not necessarily mean better).

p[1] = p[3]
p[3] = p[1]

v4[1] = v4[3]
v4[2] = v4[4]
v4[4] = v4[1]

nothing # hide

#=

The value of this swizzling functionality is more apparent when there are lots of operations of this sort, in shaders for example. Although in computer graphics, it will be much more common to use statically-sized vectors; swizzling works on them too!

=#

using StaticArrays

v = @SVector [1.0, 2.0, 3.0]
@swizzle v.xy

# `@swizzle` will attempt to recognize a top-level swizzling expression,
# therefore you may need to put parentheses and/or perform multiple
# macrocalls to swizzle different bits of a single expression.

struct ShaderData
  location::SVector{4,Float32}
  ## ...
end

data = ShaderData(@SVector [2.1, 2.2, 2.3, 2.0])

@swizzle(data.location.xyz)/@swizzle(data.location.w)

#=

That ends this brief tutorial. You may consult the [API reference](@ref Reference) for more in-depth information about syntax and functionality.

=#
