using CAN
using CANalyze

function main()

    vector1 = VectorInterface(0, 500000, "NewApp")
    vector2 = VectorInterface(1, 500000, "NewApp";
        extfilter=AcceptanceFilter(0x01, 0x01))

    println(vector1)
    println(vector2)

    frame = CANalyze.CANFrame(1, [1, 1, 2, 2, 3, 3, 4]; is_extended=true)
    send(vector1, frame)

    frame = CANalyze.CANFrame(2, [1, 1, 2, 2, 3, 3, 4]; is_extended=true)
    send(vector1, frame)

    frame = recv(vector2) # accept by filter
    println(frame)

    frame = recv(vector2) # decline by filter
    println(frame)

    shutdown(vector1)
    shutdown(vector2)
end

main()