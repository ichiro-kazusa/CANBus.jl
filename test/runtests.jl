using CANBus
using Test
using Aqua


include("core/test_frames.jl")
include("core/test_interfacecfgs.jl")

include("interfaces/test_kvaser.jl")
include("interfaces/test_vector.jl")
include("interfaces/test_socketcan.jl")
include("interfaces/test_slcan.jl")


@testset "Aqua.jl" begin
    Aqua.test_all(CANBus)
end
