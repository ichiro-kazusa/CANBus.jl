using CAN
using CANalyze
using Test

function main()

    """ to prepare test environment
    sudo modprobe vcan
    sudo ip link add dev vcan0 type vcan
    sudo ip link add dev vcan1 type vcan
    sudo ip link set up vcan0
    sudo ip link set up vcan1
    sudo modprobe can-gw
    sudo cangw -A -s vcan0 -d vcan1 -e
    sudo cangw -A -s vcan1 -d vcan0 -e
    sudo cangw -A -X -s vcan0 -d vcan1 -e
    sudo cangw -A -X -s vcan1 -d vcan0 -e
    """

    f = AcceptanceFilter(14, 0xFFFF)

    sockcan1 = SocketCANInterface("vcan0")
    sockcan2 = SocketCANInterface("vcan1"; filters=[f])

    println(sockcan1)
    println(sockcan2)

    frame = CAN.Frame(14, [1, 1, 2, 2, 3, 3, 4], true)

    send(sockcan1, frame)

    frame = recv(sockcan2) # non-blocking receive
    println(frame)

    frame = recv(sockcan2) # returns nothing
    println(frame)

    shutdown(sockcan1)
    shutdown(sockcan2)


    # use FD
    scanfd0 = SocketCANFDInterface("vcan0")
    scanfd1 = SocketCANFDInterface("vcan1")

    println(scanfd0)
    println(scanfd1)

    msg = CAN.FDFrame(14, collect(1:16), true, false, false)

    send(scanfd0, msg)

    msg = recv(scanfd1)
    println(msg)

    shutdown(scanfd0)
    shutdown(scanfd1)

    true
end

@test main()