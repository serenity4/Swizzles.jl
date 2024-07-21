module SwizzlesStaticArraysExt

using StaticArrays
using PrecompileTools
using Swizzles

import Swizzles: swizzle, swizzle!

@generated function swizzle(v::SizedVector, i, j, indices...)
  V = v.name.name
  :(swizzle($V{Tuple{2 + length(indices)},eltype(v),1,1}, v, i, j, indices...))
end

@generated function swizzle(v::StaticVector, i, j, indices...)
  V = v.name.name
  :(swizzle($V{Tuple{2 + length(indices)},eltype(v),1}, v, i, j, indices...))
end

@generated function swizzle!(v::StaticVector, value, i, indices...)
  body = Expr(:block)
  for k in 1:(1 + length(indices))
    index = k == 1 ? :i : :(indices[$(k - 1)])
    push!(body.args, :(v[$index] = value[$k]))
  end
  push!(body.args, :value)
  body
end

@compile_workload begin
  v = MVector{4,Int}((1, 2, 3, 4))
  @swizzle begin
    v.x = v.y
    v.rgb = v.zyx
    v.w = copy(v).z
  end
  @swizzle Float64 (v.x, v.y + 1, v.z)

  v = SVector{4,Int}((1, 2, 3, 4))
  @swizzle v.rgba
  @swizzle Float64 (v.x, v.y + 1, v.z)
end

end # module
