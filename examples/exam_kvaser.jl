using CANBus
using Test

function main()
    # use CAN
    kvaser1 = KvaserInterface(0, 500000; silent=true)
    kvaser2 = KvaserInterface(1, 500000;
        extfilter=AcceptanceFilter(0x01, 0x01))

    println(kvaser1)
    println(kvaser2)

    frame = Frame(1, [1, 1, 2, 2, 3, 3, 4]; is_extended=true)
    send(kvaser1, frame)

    msg = CANBus.Frame(2, [1, 1, 2, 2, 3, 3, 4]; is_extended=true)
    send(kvaser1, msg)
    sleep(0.1)

    msg1 = recv(kvaser2) # accept by filter
    println(msg1)

    msg = recv(kvaser2) # decline by filter
    println(msg)

    shutdown(kvaser1)
    shutdown(kvaser2)

    # use CAN FD
    kvaserfd1 = KvaserFDInterface(0, 500000, 2000000)
    kvaserfd2 = KvaserFDInterface(1, 500000, 2000000)
    println(kvaserfd1)
    println(kvaserfd2)

    msg = CANBus.FDFrame(1, collect(1:16); bitrate_switch=false)
    send(kvaserfd1, msg)
    sleep(0.1)
    send(kvaserfd1, msg)

    msg2 = recv(kvaserfd2)
    println(msg2)
    msg3 = recv(kvaserfd2)
    println(msg2.timestamp - msg1.timestamp)
    println(msg3.timestamp - msg2.timestamp)

    shutdown(kvaserfd1)
    shutdown(kvaserfd2)

    true
end

@test main()