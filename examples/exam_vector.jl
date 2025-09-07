using CANBus
using Test

function main()

    vector1 = VectorInterface(0, 500000, "NewApp")
    vector2 = VectorInterface(1, 500000, "NewApp";
        extfilter=AcceptanceFilter(0x01, 0x01))

    println(vector1)
    println(vector2)

    frame = CANBus.Frame(1, [1, 1, 2, 2, 3, 3, 4], true)
    send(vector1, frame)

    frame = CANBus.Frame(2, [1, 1, 2, 2, 3, 3, 4], true)
    send(vector1, frame)

    frame = recv(vector2) # accept by filter
    println(frame)

    frame = recv(vector2) # decline by filter
    println(frame)

    shutdown(vector1)
    shutdown(vector2)

    # use CAN FD
    vectorfd1 = VectorFDInterface(0, 500000, 2000000, "NewApp")
    vectorfd2 = VectorFDInterface(1, 500000, 2000000, "NewApp")
    println(vectorfd1)
    println(vectorfd2)

    msg = CANBus.FDFrame(1, collect(1:16), false, false, false)
    send(vectorfd1, msg)

    msg = recv(vectorfd2)
    println(msg)

    shutdown(vectorfd1)
    shutdown(vectorfd2)

    true
end

@test main()