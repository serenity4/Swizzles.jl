using Swizzles
using StaticArrays
using Test

@testset "Swizzles.jl" begin
  @testset "`swizzle`" begin
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

    sw = swizzle(v, 3)
    @test sw === 3

    v = Any[1, 2, 3]
    @test isa(swizzle(v, 3, 1), Vector{Any})
    @test isa(swizzle(Vector, v, 3, 1), Vector{Int})
    @test isa(swizzle(Vector{Float64}, v, 3, 1), Vector{Float64})
  end

  @testset "`swizzle!`" begin
    v = [1, 2, 3]
    @test swizzle!(v, (5, 6), 3, 1) === (5, 6)
    @test v == [6, 2, 5]

    v = @MVector [1, 2, 3]
    @test swizzle!(v, [5, 6], 3, 1) == [5, 6]
    @test v == @MVector [6, 2, 5]
  end

  @testset "`@swizzle`" begin
    v = [1, 2, 3, 4]

    sw = @swizzle v.xzw
    @test sw == [1, 3, 4]

    @test (@eval @swizzle $v.xzw) == [1, 3, 4]
    @test (@eval @swizzle $v.rab) == [1, 4, 3]
    @test (@eval @swizzle $v.xyx) == [1, 2, 1]
    @test (@eval @swizzle $v.zz) == [3, 3]
    @test (@eval @swizzle $v.zz) == [3, 3]

    @test (@eval @swizzle Tuple $v.xzw) === (1, 3, 4)
    @test (@eval @swizzle Tuple $v.rab) === (1, 4, 3)
    @test (@eval @swizzle Tuple $v.xyx) === (1, 2, 1)
    @test (@eval @swizzle Tuple $v.zz) === (3, 3)
    @test (@eval @swizzle Tuple $v.zz) === (3, 3)

    sw = @swizzle v.xzw = [11, 12, 13]
    @test sw == [11, 12, 13]
    @test v == [11, 2, 12, 13]

    sw = @swizzle v.xzw = @swizzle v.zyx
    @test sw == [12, 2, 11]
    @test v == [12, 2, 2, 11]

    v = Ref([1, 2, 3, 4])
    sw = @swizzle $(v[]).xzw = @swizzle $(v[]).zyx
    @test v[] == [3, 2, 2, 1]

    v = [1, 2, 3, 4]
    sw = @swizzle v.xzw = v.zyx
    @test v == [3, 2, 2, 1]

    a = [1, 2, 3]
    b = [4, 5, 6]
    sw = @swizzle Float64 begin
      a.z = b.x
      b.y = a.x
    end
    @test sw === 1.0 == a[1]
    @test a == [1, 2, 4]
    @test b == [4, 1, 6]

    @test_throws "Expected `QuoteNode` value in `swizzle`" @eval @swizzle $(Expr(:., :(QuoteNode(v)), 3))
    @test_throws "Expected symbol `QuoteNode` value in `swizzle`" @eval @swizzle $(Expr(:., :(QuoteNode(v)), QuoteNode(3)))
  end

  @testset "Custom swizzling" begin
    if VERSION ≥ v"1.11-DEV"
      @eval macro _swizzle(ex)
        new_names = Dict('w' => 1, 'h' => 2, 'd' => 3)
        component_names = merge(Swizzles.component_names[], new_names)
        swizzle_ex = @with Swizzles.component_names => component_names begin
          Swizzles.generate_swizzle_expr(ex)
        end
        esc(swizzle_ex)
      end

      v = [10, 20, 30]
      sw = @eval @_swizzle $v.dwh
      @test sw == [30, 10, 20]

      sw = @eval @_swizzle $v.hw = (1, 4)
      @test sw === (1, 4)
      @test v == [4, 1, 30]

      sw = @eval @_swizzle $v.hw
      @test sw == [1, 4]
    end
  end
end;
