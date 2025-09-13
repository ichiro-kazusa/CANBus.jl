using CANBus
using Test

function test_kvaser_normal()
    # use CAN
    kvaser1 = KvaserInterface(0, 500000)
    kvaser2 = KvaserInterface(1, 500000,
        extfilter=AcceptanceFilter(0x01, 0x01))

    msg_t1 = CANBus.Frame(1, [1, 1, 2, 2, 3, 3, 4]; is_extended=true)
    send(kvaser1, msg_t1)

    msg_t2 = CANBus.Frame(2, [1, 1, 2, 2, 3, 3, 4]; is_extended=true)
    send(kvaser1, msg_t2) # decline by filter

    sleep(0.1)

    msg_r = recv(kvaser2) # accept by filter
    @assert msg_r == msg_t1

    msg_r = recv(kvaser2) # decline by filter
    @assert msg_r === nothing

    msg_r = recv(kvaser2) # receive nothing
    @assert msg_r === nothing

    ret = shutdown(kvaser1)
    @assert ret === nothing
    shutdown(kvaser2)

    true
end


function test_kvaser_nodevice()
    KvaserInterface(10, 500000) # must be error
end


function test_kvaser_invalidrate()
    KvaserInterface(10, -500000) # must be error
end


function test_kvaser_normal_fd()
    kvaserfd1 = KvaserFDInterface(0, 500000, 2000000)
    kvaserfd2 = KvaserFDInterface(1, 500000, 2000000;
        extfilter=AcceptanceFilter(0x01, 0x01))

    msg_t = CANBus.FDFrame(1, collect(1:16); bitrate_switch=false)
    send(kvaserfd1, msg_t)
    sleep(0.1)

    msg_r = recv(kvaserfd2)
    @assert msg_t == msg_r

    msg_t = CANBus.FDFrame(1, collect(1:16))
    send(kvaserfd1, msg_t)
    sleep(0.1)

    msg_r = recv(kvaserfd2)
    @assert msg_t == msg_r

    msg_t = CANBus.FDFrame(2, collect(1:16); is_extended=true)
    send(kvaserfd1, msg_t)
    sleep(0.1)

    msg_r = recv(kvaserfd2) # filtered
    @assert msg_r === nothing

    msg_r = recv(kvaserfd2) # empty
    @assert msg_r === nothing

    shutdown(kvaserfd1)
    shutdown(kvaserfd2)

    true
end


# This feature can not be able to test on GitHub Actions.
if !haskey(ENV, "GITHUB_ACTIONS") && Sys.iswindows()
    @testset "Kvaser" begin
        @test test_kvaser_normal()
        @test_throws ErrorException test_kvaser_nodevice()
        @test_throws ErrorException test_kvaser_invalidrate()
        @test test_kvaser_normal_fd()
    end
end
