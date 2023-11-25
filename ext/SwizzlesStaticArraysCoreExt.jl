module SwizzlesStaticArraysCoreExt

using StaticArraysCore
using StaticArraysCore: StaticVector
using Swizzles

import Swizzles: swizzle

@generated function swizzle(v::SizedVector, i, j, indices...)
  V = v.name.name
  :(swizzle($V{Tuple{2 + length(indices)},eltype(v),1,1}, v, i, j, indices...))
end

@generated function swizzle(v::StaticVector, i, j, indices...)
  V = v.name.name
  :(swizzle($V{Tuple{2 + length(indices)},eltype(v),1}, v, i, j, indices...))
end

end # module
