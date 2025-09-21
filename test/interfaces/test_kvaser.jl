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

    msg_t = CANBus.FDFrame(1, collect(1:16)) # first message
    send(kvaserfd1, msg_t)
    sleep(1)
    msg_t = CANBus.FDFrame(1, collect(1:16)) # check timestamp
    send(kvaserfd1, msg_t)
    
    sleep(0.1) # wait for arrive

    msg_r1 = recv(kvaserfd2)
    @assert msg_t == msg_r1

    msg_r2 = recv(kvaserfd2)
    @assert 0.999 <= msg_r2.timestamp - msg_r1.timestamp <= 1.01 # check timestamp

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



function test_kvaser_timeout()

    kvaserfd1 = KvaserFDInterface(0, 500000, 2000000)
    kvaserfd2 = KvaserFDInterface(1, 500000, 2000000)

    # compile
    msg_t = CANBus.FDFrame(1, collect(1:16); bitrate_switch=false)
    send(kvaserfd2, msg_t)
    recv(kvaserfd1)
    sleep(0.1)

    # tests
    res = @elapsed begin
        ret = recv(kvaserfd1; timeout_s=1)
        @assert ret === nothing
    end
    @assert 0.9 < res < 1.1

    res = @elapsed begin
        ret = recv(kvaserfd1)
        @assert ret === nothing
    end
    @assert 0. < res < 0.1


    t1 = @async begin
        res = @elapsed begin
            recv(kvaserfd1; timeout_s=2)
        end
        res
    end

    t2 = @async begin
        sleep(1)
        send(kvaserfd2, msg_t)
    end

    res = fetch(t1)
    wait(t2)

    @assert 0.9 < res < 1.1

    shutdown(kvaserfd1)
    shutdown(kvaserfd2)

    true
end


function test_kvaser_do_end()
    KvaserInterface(0, 500000) do kvaser
        msg_t = CANBus.Frame(1, [1, 1, 2, 2, 3, 3, 4]; is_extended=true)
        send(kvaser, msg_t)
    end

    KvaserFDInterface(0, 500000, 2000000) do kvaser
        msg_t = CANBus.Frame(1, [1, 1, 2, 2, 3, 3, 4]; is_extended=true)
        send(kvaser, msg_t)
    end

    true
end


# This feature can not be able to test on GitHub Actions.
if !haskey(ENV, "GITHUB_ACTIONS") && Sys.iswindows()
    @testset "Kvaser" begin
        @test test_kvaser_normal()
        @test_throws ErrorException test_kvaser_nodevice()
        @test_throws ErrorException test_kvaser_invalidrate()
        @test test_kvaser_normal_fd()
        @test test_kvaser_timeout()
        @test test_kvaser_do_end()
    end
end
