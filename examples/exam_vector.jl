using CANBus
using Test

function main()

    vector1 = VectorInterface(0, 500000, "NewApp")
    vector2 = VectorInterface(1, 500000, "NewApp";
        extfilter=AcceptanceFilter(0x01, 0x01))

    println(vector1)
    println(vector2)

    frame = CANBus.Frame(1, [1, 1, 2, 2, 3, 3, 4]; is_extended=true)
    send(vector1, frame)

    frame = CANBus.Frame(2, [1, 1, 2, 2, 3, 3, 4]; is_extended=true)
    send(vector1, frame)

    sleep(0.1) # wait arrive

    frame1 = recv(vector2) # accept by filter
    println(frame1)

    frame = recv(vector2) # decline by filter
    println(frame)

    shutdown(vector1)
    shutdown(vector2)

    # use CAN FD
    vectorfd1 = VectorFDInterface(0, 500000, 2000000, "NewApp")
    vectorfd2 = VectorFDInterface(1, 500000, 2000000, "NewApp")
    println(vectorfd1)
    println(vectorfd2)

    msg = CANBus.FDFrame(1, collect(1:16); bitrate_switch=false)
    send(vectorfd1, msg)
    sleep(1)
    msg = CANBus.FDFrame(1, collect(1:16); bitrate_switch=false)
    send(vectorfd1, msg)

    sleep(0.1) # wait arrive

    msg_1 = recv(vectorfd2)
    println(msg_1)
    msg_2 = recv(vectorfd2)
    println(msg_2)

    shutdown(vectorfd1)
    shutdown(vectorfd2)

    println(msg_1.timestamp - frame1.timestamp)
    println(msg_2.timestamp - msg_1.timestamp)

    true
end

@test main()