using CANBus
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

    frame = CANBus.Frame(14, [1, 1, 2, 2, 3, 3, 4]; is_extended=true)

    send(sockcan1, frame)

    sleep(0.1) # wait for arrive

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

    msg1 = CANBus.FDFrame(14, collect(1:16); is_extended=true, bitrate_switch=false)
    msg2 = CANBus.Frame(14, [1, 1, 2, 2, 3, 3, 4]; is_extended=true)

    send(scanfd0, msg1) # FD frame
    sleep(0.5) # check timestamp
    send(scanfd0, msg2) # FD interface can send classic frame

    sleep(0.1) # wait for arrive

    msg_r1 = recv(scanfd1) # receive fd message
    println(msg_r1)
    msg_r2 = recv(scanfd1) # receive classic message
    println(msg_r2)
    msg_r3 = recv(scanfd1) # receive nothing
    println(msg_r3)

    println(msg_r2.timestamp - msg_r1.timestamp)

    shutdown(scanfd0)
    shutdown(scanfd1)

    true
end

@test main()