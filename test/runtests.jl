using CANBus
using Test
using Aqua


include("frames/test_frames.jl")
include("interfaces/test_kvaser.jl")
include("interfaces/test_vector.jl")
include("interfaces/test_socketcan.jl")
include("interfaces/test_slcan.jl")

include("test_examples.jl")


@testset "Aqua.jl" begin
    Aqua.test_all(CANBus)
end
