using Swizzles
using StaticArrays
using Test

@testset "Swizzles.jl" begin
  v = [1, 2, 3]
  @test swizzle(Tuple, v, 1, 3) === (1, 3)
  sw = swizzle(v, 1, 3)
  @test isa(sw, Vector{Int})
  @test sw == [1, 3]
  sw = swizzle(v, 1, 3, 3)
  @test sw == [1, 3, 3]

  v = @SVector [1.0, 2.0, 3.0]
  sw = swizzle(v, 1, 3)
  @test sw === @SVector [1.0, 3.0]

  v = @MVector [1.0, 2.0, 3.0]
  sw = swizzle(v, 1, 3)
  @test sw == @MVector [1.0, 3.0]

  v = SizedVector{3}([1, 2, 3])
  sw = swizzle(v, 1, 3)
  @test sw == SizedVector{2}([1.0, 3.0])
end;
