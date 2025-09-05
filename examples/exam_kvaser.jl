using CAN
using CANalyze

function main()
    # use CAN
    kvaser1 = KvaserInterface(0, 500000; silent=true)
    kvaser2 = KvaserInterface(1, 500000;
        extfilter=AcceptanceFilter(0x01, 0x01))

    println(kvaser1)
    println(kvaser2)

    frame = CANalyze.CANFrame(1, [1, 1, 2, 2, 3, 3, 4]; is_extended=true)
    msg = CAN.CANMessage(frame)
    send(kvaser1, msg)

    msg = CAN.CANMessage(2, [1, 1, 2, 2, 3, 3, 4], true)
    send(kvaser1, msg)

    msg = recv(kvaser2) # accept by filter
    println(msg)

    msg = recv(kvaser2) # decline by filter
    println(msg)

    shutdown(kvaser1)
    shutdown(kvaser2)

    # use CAN FD
    kvaserfd1 = KvaserFDInterface(0, 500000, 2000000)
    kvaserfd2 = KvaserFDInterface(1, 500000, 2000000)
    println(kvaserfd1)
    println(kvaserfd2)

    msg = CAN.CANFDMessage(1, collect(1:16), false, false, false)
    send(kvaserfd1, msg)

    msg = recv(kvaserfd2)
    println(msg)

    shutdown(kvaserfd1)
    shutdown(kvaserfd2)
end

main()