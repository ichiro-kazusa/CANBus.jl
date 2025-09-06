using Test


@testset "Examples" begin
    include("../examples/exam_decode.jl")
    if !haskey(ENV, "GITHUB_ACTIONS")
        if Sys.iswindows()
            include("../examples/exam_kvaser.jl")
            include("../examples/exam_vector.jl")
        elseif Sys.islinux()
            include("../examples/exam_socketcan.jl")
        end
    end
end