using CANBus
using Test

function test_slcan_normal()
    # use CAN
    scan1 = SlcanInterface("COM3", 1000000)
    scan2 = SlcanInterface("COM4", 1000000)

    msg_t1 = CANBus.Frame(1, [1, 1, 2, 2, 3, 3, 4], true)
    send(scan1, msg_t1)

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

    msg_t = CANBus.FDFrame(1, collect(1:16), false, false, false)
    send(scanfd1, msg_t) # normal FD

    msg_r = recv(scanfd2)
    @assert msg_t == msg_r

    msg_t = CANBus.FDFrame(1, collect(1:16), false, true, false)
    send(scanfd1, msg_t) # bitrate switch

    msg_r = recv(scanfd2)
    @assert msg_t == msg_r

    msg_t = CANBus.Frame(2, collect(1:7), true)
    send(scanfd1, msg_t)

    msg_r = recv(scanfd2) # classic frame
    @assert msg_r == msg_t

    shutdown(scanfd1)
    shutdown(scanfd2)

    true
end


# This feature can not be able to test on GitHub Actions.
if !haskey(ENV, "GITHUB_ACTIONS") && (Sys.islinux() || Sys.iswindows())
    @testset "slcan" begin
        @test test_slcan_normal()
        @test_throws ErrorException test_slcan_nodevice()
        @test test_slcan_normal_fd()
    end
end
