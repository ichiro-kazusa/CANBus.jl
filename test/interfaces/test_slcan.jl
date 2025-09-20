using CANBus
using Test

function test_slcan_normal()
    # use CAN
    scan1 = SlcanInterface("COM3", 1000000)
    scan2 = SlcanInterface("COM4", 1000000)

    msg_t1 = CANBus.Frame(1, [1, 1, 2, 2, 3, 3, 4]; is_extended=true)
    send(scan1, msg_t1)

    sleep(0.1)

    msg_r = recv(scan2)
    @assert msg_r == msg_t1

    msg_r = recv(scan2) # receive nothing
    @assert msg_r === nothing

    ret = shutdown(scan1)
    @assert ret === nothing
    shutdown(scan2)

    true
end


function test_slcan_nodevice()
    SocketCANInterface("vcan2") # must be error
end



function test_slcan_normal_fd()
    scanfd1 = SlcanFDInterface("COM3", 1000000, 2000000)
    scanfd2 = SlcanFDInterface("COM4", 1000000, 2000000)

    msg_t = CANBus.FDFrame(1, collect(1:16); bitrate_switch=false)
    send(scanfd1, msg_t) # normal FD

    sleep(0.1)

    msg_r = recv(scanfd2)
    @assert msg_t == msg_r

    msg_t = CANBus.FDFrame(1, collect(1:16))
    send(scanfd1, msg_t) # bitrate switch

    sleep(0.1)

    msg_r = recv(scanfd2)
    @assert msg_t == msg_r

    msg_t = CANBus.Frame(2, collect(1:7); is_extended=true)
    send(scanfd1, msg_t)

    sleep(0.1)

    msg_r = recv(scanfd2) # classic frame
    @assert msg_r == msg_t

    shutdown(scanfd1)
    shutdown(scanfd2)

    true
end


function test_slcan_timeout()

    slcanfd1 = SlcanFDInterface("COM3", 500000, 2000000)
    slcanfd2 = SlcanFDInterface("COM4", 500000, 2000000)

    # compile
    msg_t = CANBus.FDFrame(1, collect(1:16); bitrate_switch=false)
    send(slcanfd2, msg_t)
    sleep(0.1)
    recv(slcanfd1)
    sleep(0.1)

    # tests
    res = @elapsed begin # timeout 1s
        ret = recv(slcanfd1; timeout_s=1)
        @assert ret === nothing
    end
    @assert 0.9 < res < 1.2

    res = @elapsed begin # non-blocking
        ret = recv(slcanfd1)
        @assert ret === nothing
    end
    @assert 0. < res < 0.2


    t1 = @async begin # receive in 1s
        res = @elapsed begin
            recv(slcanfd1; timeout_s=2)
        end
        res
    end

    t2 = @async begin # async send to task1
        sleep(1)
        send(slcanfd2, msg_t)
    end

    res = fetch(t1)
    wait(t2)

    @assert 0.9 < res < 1.2

    shutdown(slcanfd1)
    shutdown(slcanfd2)

    true
end


# This feature can not be able to test on GitHub Actions.
if !haskey(ENV, "GITHUB_ACTIONS") && (Sys.islinux() || Sys.iswindows())
    @testset "slcan" begin
        @test test_slcan_normal()
        @test_throws ErrorException test_slcan_nodevice()
        @test test_slcan_normal_fd()
        @test test_slcan_timeout()
    end
end
