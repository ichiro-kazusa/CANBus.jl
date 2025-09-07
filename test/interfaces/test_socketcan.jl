using CANBus
using Test

function test_scan_normal()
    # use CAN
    scan1 = SocketCANInterface("vcan0")
    scan2 = SocketCANInterface("vcan1";
        filters=[AcceptanceFilter(0x01, 0x01)])

    msg_t1 = CANBus.Frame(1, [1, 1, 2, 2, 3, 3, 4], true)
    send(scan1, msg_t1)

    msg_t2 = CANBus.Frame(2, [1, 1, 2, 2, 3, 3, 4], true)
    send(scan1, msg_t2) # decline by filter


    msg_r = recv(scan2) # accept by filter
    @assert msg_r == msg_t1

    msg_r = recv(scan2) # decline by filter
    @assert msg_r === nothing

    msg_r = recv(scan2) # receive nothing
    @assert msg_r === nothing

    ret = shutdown(scan1)
    @assert ret === nothing
    shutdown(scan2)

    true
end


function test_scan_nodevice()
    SocketCANInterface("vcan2") # must be error
end



function test_scan_normal_fd()
    scanfd1 = SocketCANFDInterface("vcan0")
    scanfd2 = SocketCANFDInterface("vcan1";
        filters=[AcceptanceFilter(0x01, 0x01)])

    msg_t = CANBus.FDFrame(1, collect(1:16), false, false, false)
    send(scanfd1, msg_t)

    msg_r = recv(scanfd2)
    @assert msg_t == msg_r

    msg_t = CANBus.FDFrame(1, collect(1:16), false, true, false)
    send(scanfd1, msg_t)

    msg_r = recv(scanfd2)
    @assert msg_t == msg_r

    msg_t = CANBus.FDFrame(2, collect(1:16), true, true, false)
    send(scanfd1, msg_t)
    msg_r = recv(scanfd2) # filtered
    @assert msg_r === nothing

    msg_r = recv(scanfd2) # empty
    @assert msg_r === nothing

    shutdown(scanfd1)
    shutdown(scanfd2)

    true
end


# This feature can not be able to test on GitHub Actions.
if !haskey(ENV, "GITHUB_ACTIONS") && Sys.islinux()
    @testset "SocketCAN" begin
        @test test_scan_normal()
        @test_throws ErrorException test_scan_nodevice()
        @test test_scan_normal_fd()
    end
end
