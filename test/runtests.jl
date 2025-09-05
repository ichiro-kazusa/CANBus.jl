using CAN
using Test
using Aqua


include("messages/test_messages.jl")
include("interfaces/test_kvaser.jl")
include("interfaces/test_vector.jl")



@testset "Aqua.jl" begin
    Aqua.test_all(CAN)
end
