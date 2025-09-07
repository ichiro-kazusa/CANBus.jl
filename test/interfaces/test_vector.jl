using CANBus
using Test

function test_vector_normal()
    # use CAN
    vector1 = VectorInterface(0, 500000, "NewApp")
    vector2 = VectorInterface(1, 500000, "NewApp";
        extfilter=AcceptanceFilter(0x01, 0x01))

    msg_t1 = CANBus.Frame(1, [1, 1, 2, 2, 3, 3, 4], true)
    send(vector1, msg_t1)

    msg_t2 = CANBus.Frame(2, [1, 1, 2, 2, 3, 3, 4], true)
    send(vector1, msg_t2) # decline by filter


    msg_r = recv(vector2) # accept by filter
    @assert msg_r == msg_t1

    msg_r = recv(vector2) # decline by filter
    @assert msg_r === nothing

    msg_r = recv(vector2) # receive nothing
    @assert msg_r === nothing

    ret = shutdown(vector1)
    @assert ret === nothing
    shutdown(vector2)

    true
end


function test_vector_nodevice()
    VectorInterface(10, 500000, "NewApp") # must be error
end


function test_vector_invalidrate()
    VectorInterface(10, -500000, "NewApp") # must be error
end


function test_vector_normal_fd()
    vectorfd1 = VectorFDInterface(0, 500000, 2000000, "NewApp")
    vectorfd2 = VectorFDInterface(1, 500000, 2000000, "NewApp";
        extfilter=AcceptanceFilter(0x01, 0x01))

    msg_t = CANBus.FDFrame(1, collect(1:16), false, false, false)
    send(vectorfd1, msg_t)

    msg_r = recv(vectorfd2)
    @assert msg_t == msg_r

    msg_t = CANBus.FDFrame(1, collect(1:16), false, true, false)
    send(vectorfd1, msg_t)

    msg_r = recv(vectorfd2)
    @assert msg_t == msg_r

    msg_t = CANBus.FDFrame(2, collect(1:16), true, true, false)
    send(vectorfd1, msg_t)
    msg_r = recv(vectorfd2) # filtered
    @assert msg_r === nothing

    msg_r = recv(vectorfd2) # empty
    @assert msg_r === nothing

    shutdown(vectorfd1)
    shutdown(vectorfd2)

    true
end


# This feature can not be able to test on GitHub Actions.
if !haskey(ENV, "GITHUB_ACTIONS") && Sys.iswindows()
    @testset "Vector" begin
        @test test_vector_normal()
        @test_throws ErrorException test_vector_nodevice()
        @test_throws ErrorException test_vector_invalidrate()
        @test test_vector_normal_fd()
    end
end
