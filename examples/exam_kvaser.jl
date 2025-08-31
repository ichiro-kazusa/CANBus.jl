using CAN
using CANalyze

function main()
    kvaser1 = KvaserInterface(0, 500000)
    kvaser2 = KvaserInterface(1, 500000;
        extfilter=AcceptanceFilter(0x01, 0x01))

    println(kvaser1)
    println(kvaser2)

    frame = CANalyze.CANFrame(1, [1, 1, 2, 2, 3, 3, 4]; is_extended=true)
    send(kvaser1, frame)

    frame = CANalyze.CANFrame(2, [1, 1, 2, 2, 3, 3, 4]; is_extended=true)
    send(kvaser1, frame)

    frame = recv(kvaser2) # accept by filter
    println(frame)

    frame = recv(kvaser2) # decline by filter
    println(frame)

    shutdown(kvaser1)
    shutdown(kvaser2)
end

main()